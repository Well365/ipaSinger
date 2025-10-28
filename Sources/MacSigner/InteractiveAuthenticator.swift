import Foundation
import Combine
import AppKit

class InteractiveAuthenticator: ObservableObject {
    @Published var isRunning = false
    @Published var needsTwoFactor = false
    @Published var output = ""
    @Published var error: String?
    @Published var sessionCreated = false
    
    private var process: Process?
    private var inputPipe: Pipe?
    private var cancellables = Set<AnyCancellable>()
    private var setGlobalEnvironment = true
    
    func startAuthentication(appleId: String, password: String, fastlaneRoot: URL, useAppSpecificPassword: Bool = true, setGlobalEnvironment: Bool = true) {
        guard !isRunning else { return }
        
        self.setGlobalEnvironment = setGlobalEnvironment
        isRunning = true
        needsTwoFactor = false
        output = "开始认证...\n"
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            if useAppSpecificPassword {
                self.runSpaceauthWithAppSpecificPassword(appleId: appleId, password: password, fastlaneRoot: fastlaneRoot)
            } else {
                self.runSpaceauthWithAccountPassword(appleId: appleId, password: password, fastlaneRoot: fastlaneRoot)
            }
        }
    }
    
    private func runSpaceauthWithAppSpecificPassword(appleId: String, password: String, fastlaneRoot: URL) {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-lc", "cd '\(fastlaneRoot.path)' && rbenv exec bundle exec fastlane spaceauth -u '\(appleId)'"]
        process.currentDirectoryURL = fastlaneRoot
        
        // 设置环境变量 - 使用应用专属密码
        var env = ProcessInfo.processInfo.environment
        env["FASTLANE_USER"] = appleId
        env["FASTLANE_PASSWORD"] = password
        env["LANG"] = "en_US.UTF-8"
        env["LC_ALL"] = "en_US.UTF-8"
        env["FASTLANE_DISABLE_COLORS"] = "1"
        env["FASTLANE_SKIP_UPDATE_CHECK"] = "1"
        env["FASTLANE_OPT_OUT_USAGE"] = "1"
        process.environment = env
        
        self.process = process
        self.inputPipe = inputPipe
        
        self.executeProcess(process: process, inputPipe: inputPipe, outputPipe: outputPipe, errorPipe: errorPipe)
    }
    
    private func runSpaceauthWithAccountPassword(appleId: String, password: String, fastlaneRoot: URL) {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-lc", "cd '\(fastlaneRoot.path)' && rbenv exec bundle exec fastlane spaceauth -u '\(appleId)'"]
        process.currentDirectoryURL = fastlaneRoot
        
        // 设置环境变量 - 使用账号密码（不设置FASTLANE_PASSWORD，让它交互式输入）
        var env = ProcessInfo.processInfo.environment
        env["FASTLANE_USER"] = appleId
        env["LANG"] = "en_US.UTF-8"
        env["LC_ALL"] = "en_US.UTF-8"
        env["FASTLANE_DISABLE_COLORS"] = "1"
        env["FASTLANE_SKIP_UPDATE_CHECK"] = "1"
        env["FASTLANE_OPT_OUT_USAGE"] = "1"
        process.environment = env
        
        self.process = process
        self.inputPipe = inputPipe
        
        // 存储密码以供后续输入
        DispatchQueue.main.async {
            self.output.append("使用账号密码模式，将交互式输入密码和验证码\n")
        }
        
        self.executeProcess(process: process, inputPipe: inputPipe, outputPipe: outputPipe, errorPipe: errorPipe, accountPassword: password)
    }
    
    private func executeProcess(process: Process, inputPipe: Pipe, outputPipe: Pipe, errorPipe: Pipe, accountPassword: String? = nil) {
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            // 监听输出
            self.monitorOutput(outputPipe: outputPipe, errorPipe: errorPipe, accountPassword: accountPassword)
            
            // 等待进程结束
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                self.cleanup()
            }
            
        } catch {
            DispatchQueue.main.async {
                self.error = "启动认证进程失败: \(error.localizedDescription)"
                self.cleanup()
            }
        }
    }
    
    func submitTwoFactorCode(_ code: String) {
        guard let inputPipe = inputPipe, isRunning else { return }
        
        let codeData = "\(code)\n".data(using: .utf8) ?? Data()
        inputPipe.fileHandleForWriting.write(codeData)
        
        DispatchQueue.main.async {
            self.output.append("提交验证码: \(code)\n")
            self.needsTwoFactor = false
        }
    }
    
    func cancel() {
        process?.terminate()
        cleanup()
    }
    
    private func monitorOutput(outputPipe: Pipe, errorPipe: Pipe, accountPassword: String? = nil) {
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        var hasInputPassword = false
        
        // 监听标准输出
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output.append(string)
                    
                    // 检查是否需要输入密码（账号密码模式）
                    if let password = accountPassword, !hasInputPassword {
                        if string.lowercased().contains("password") || 
                           string.lowercased().contains("请输入密码") ||
                           string.lowercased().contains("enter password") {
                            // 自动输入账号密码
                            DispatchQueue.global().async {
                                if let inputPipe = self.inputPipe {
                                    let passwordData = "\(password)\n".data(using: .utf8) ?? Data()
                                    inputPipe.fileHandleForWriting.write(passwordData)
                                    hasInputPassword = true
                                    DispatchQueue.main.async {
                                        self.output.append("[自动输入] 账号密码已输入\n")
                                    }
                                }
                            }
                        }
                    }
                    
                    self.checkForTwoFactorPrompt(in: string)
                    self.checkForSessionToken(in: string)
                }
            }
        }
        
        // 监听错误输出
        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output.append(string)
                    
                    // 同样检查错误输出中的密码提示
                    if let password = accountPassword, !hasInputPassword {
                        if string.lowercased().contains("password") || 
                           string.lowercased().contains("请输入密码") ||
                           string.lowercased().contains("enter password") {
                            DispatchQueue.global().async {
                                if let inputPipe = self.inputPipe {
                                    let passwordData = "\(password)\n".data(using: .utf8) ?? Data()
                                    inputPipe.fileHandleForWriting.write(passwordData)
                                    hasInputPassword = true
                                    DispatchQueue.main.async {
                                        self.output.append("[自动输入] 账号密码已输入\n")
                                    }
                                }
                            }
                        }
                    }
                    
                    self.checkForTwoFactorPrompt(in: string)
                }
            }
        }
    }
    
    private func checkForTwoFactorPrompt(in text: String) {
        let patterns = [
            "Please enter the",
            "verification code",
            "enter the 6 digit code",
            "Enter the verification code"
        ]
        
        for pattern in patterns {
            if text.lowercased().contains(pattern.lowercased()) {
                needsTwoFactor = true
                break
            }
        }
    }
    
    private func checkForSessionToken(in text: String) {
        // 查找 FASTLANE_SESSION
        if let range = text.range(of: "export FASTLANE_SESSION='") {
            let afterStart = text[range.upperBound...]
            if let endRange = afterStart.range(of: "'") {
                let sessionToken = String(afterStart[..<endRange.lowerBound])
                
                DispatchQueue.main.async {
                    self.handleSessionTokenReceived(sessionToken)
                }
            }
        }
    }
    
    private func handleSessionTokenReceived(_ token: String) {
        // 设置当前进程环境变量
        setenv("FASTLANE_SESSION", token, 1)
        
        // 保存到 SessionMonitor
        let sessionMonitor = SessionMonitor()
        sessionMonitor.saveSession(token)
        
        // 根据设置决定是否设置到全局shell环境
        if setGlobalEnvironment {
            setGlobalEnvironmentVariable(token: token)
        }
        
        // 复制到剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("export FASTLANE_SESSION='\(token)'", forType: NSPasteboard.PasteboardType.string)
        
        output.append("\n✅ Session Token 设置成功！\n")
        output.append("已复制到剪贴板并设置当前进程环境变量\n")
        
        if setGlobalEnvironment {
            output.append("已设置到全局shell环境（.zshrc, .bash_profile）\n")
            output.append("新终端窗口中可使用: echo $FASTLANE_SESSION\n")
        } else {
            output.append("仅在当前应用进程中设置环境变量\n")
        }
        
        // 保存凭证
        let credential = LoginCredential(
            appleId: ProcessInfo.processInfo.environment["FASTLANE_USER"] ?? "",
            sessionToken: token,
            sessionExpiryDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        )
        try? KeychainStore.saveCredential(credential)
        
        sessionCreated = true
        cleanup()
    }
    
    private func setGlobalEnvironmentVariable(token: String) {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let exportLine = "export FASTLANE_SESSION='\(token)'"
        
        // 获取当前用户的shell
        let currentShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        
        // 根据shell类型确定配置文件
        var configFiles: [String] = []
        
        if currentShell.contains("zsh") {
            configFiles = [".zshrc", ".zprofile"]
        } else if currentShell.contains("bash") {
            configFiles = [".bash_profile", ".bashrc"]
        } else {
            // 默认尝试常见的配置文件
            configFiles = [".zshrc", ".bash_profile", ".profile"]
        }
        
        for configFile in configFiles {
            let configPath = homeDirectory.appendingPathComponent(configFile)
            updateShellConfig(at: configPath, with: exportLine)
        }
        
        DispatchQueue.main.async {
            self.output.append("已更新shell配置文件: \(configFiles.joined(separator: ", "))\n")
        }
    }
    
    private func updateShellConfig(at configPath: URL, with exportLine: String) {
        let fileManager = FileManager.default
        
        do {
            var content = ""
            
            // 读取现有内容
            if fileManager.fileExists(atPath: configPath.path) {
                content = try String(contentsOf: configPath, encoding: .utf8)
            }
            
            // 检查是否已经存在FASTLANE_SESSION配置
            let lines = content.components(separatedBy: .newlines)
            var newLines: [String] = []
            var foundExisting = false
            
            for line in lines {
                if line.trimmingCharacters(in: .whitespaces).starts(with: "export FASTLANE_SESSION=") {
                    // 替换现有的配置
                    newLines.append(exportLine)
                    foundExisting = true
                } else {
                    newLines.append(line)
                }
            }
            
            // 如果没有找到现有配置，添加新的
            if !foundExisting {
                if !content.isEmpty && !content.hasSuffix("\n") {
                    newLines.append("")
                }
                newLines.append("# FASTLANE_SESSION - Auto-generated by MacSigner")
                newLines.append(exportLine)
            }
            
            // 写回文件
            let newContent = newLines.joined(separator: "\n")
            try newContent.write(to: configPath, atomically: true, encoding: .utf8)
            
        } catch {
            DispatchQueue.main.async {
                self.output.append("警告: 无法更新 \(configPath.lastPathComponent): \(error.localizedDescription)\n")
            }
        }
    }
    
    private func cleanup() {
        isRunning = false
        needsTwoFactor = false
        
        process?.terminate()
        process = nil
        
        inputPipe?.fileHandleForWriting.closeFile()
        inputPipe = nil
    }
}