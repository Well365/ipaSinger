import SwiftUI
import Foundation

class SignerManager: ObservableObject {
    @Published var isRunning = false
    @Published var logs: [String] = []
    @Published var config: Config
    @Published var currentCredential: LoginCredential?
    
    private var signerTask: Task<Void, Never>?
    private var api: APIClient
    private var executor: SignExecutor
    
    init(initialConfig: Config = Config.load()) {
        let resolvedConfig = initialConfig
        self.config = resolvedConfig
        self.api = APIClient(config: resolvedConfig)
        let fastlaneDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("fastlane")
        self.executor = FastlaneSignExecutor(fastlaneDir: fastlaneDir)
        self.currentCredential = KeychainStore.loadCredential()
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        addLog("[INFO] MacSigner 启动中...")
        
        signerTask = Task {
            await runSignerLoop()
        }
    }
    
    func stop() {
        signerTask?.cancel()
        signerTask = nil
        isRunning = false
        addLog("[INFO] MacSigner 已停止")
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func updateConfig(_ newConfig: Config) {
        self.config = newConfig
        self.api = APIClient(config: newConfig)
        addLog("[INFO] 配置已更新")
    }
    
    func updateCredential(_ credential: LoginCredential) {
        do {
            try KeychainStore.saveCredential(credential)
            self.currentCredential = credential
            addLog("[INFO] 凭证已更新: \(credential.appleId)")
        } catch {
            addLog("[ERROR] 保存凭证失败: \(error)")
        }
    }
    
    private func addLog(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            self.logs.append("[\(timestamp)] \(message)")
            
            // 限制日志数量
            if self.logs.count > 1000 {
                self.logs.removeFirst(100)
            }
        }
    }
    
    private func runSignerLoop() async {
        addLog("[INFO] 服务器: \(config.serverBaseURL.absoluteString), 轮询间隔: \(config.pollIntervalSec)秒")
        
        // 验证凭证
        if let cred = currentCredential {
            do {
                try await executor.ensureLogin(credential: cred)
                addLog("[INFO] 凭证验证成功: \(cred.appleId)")
            } catch {
                addLog("[ERROR] 凭证验证失败: \(error)")
            }
        } else {
            addLog("[WARN] 未找到凭证，请在设置中配置")
        }
        
        while !Task.isCancelled && isRunning {
            do {
                if let task = try await api.fetchOneTask() {
                    addLog("[INFO] 获取到任务 \(task.taskId), ipaId=\(task.ipaId), udid=\(task.udid)")
                    try await api.reportStatus(taskId: task.taskId, status: .running)
                    
                    // 下载IPA文件
                    addLog("[INFO] 开始下载IPA文件...")
                    try await downloadIPA(ipaId: task.ipaId)
                    
                    // 注册UDID
                    addLog("[INFO] 注册设备UDID: \(task.udid)")
                    try await executor.registerUDID(task.udid, bundleId: task.bundleId)
                    
                    // 重签名IPA
                    addLog("[INFO] 开始重签名IPA...")
                    let ipaURL = try await executor.resignIPA(ipaId: task.ipaId, options: task.resignOptions)
                    
                    // 上传结果
                    addLog("[INFO] 上传重签名后的IPA...")
                    let downloadURL = try await uploadSignedIPA(ipaURL)
                    
                    try await api.uploadResult(taskId: task.taskId, downloadURL: downloadURL)
                    try await api.reportStatus(taskId: task.taskId, status: .success, message: "签名完成")
                    addLog("[INFO] 任务 \(task.taskId) 完成")
                } else {
                    addLog("[INFO] 无任务，等待 \(config.pollIntervalSec) 秒...")
                    try await Task.sleep(nanoseconds: UInt64(config.pollIntervalSec) * 1_000_000_000)
                }
            } catch {
                addLog("[ERROR] 处理错误: \(error)")
                try? await Task.sleep(nanoseconds: UInt64(config.pollIntervalSec) * 1_000_000_000)
            }
        }
    }
    
    // 下载IPA文件的实现
    private func downloadIPA(ipaId: String) async throws {
        let localPath = "/tmp/\(ipaId).ipa"
        let url = config.serverBaseURL.appendingPathComponent("api/ipa/\(ipaId)/download")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Download", code: 1, userInfo: [NSLocalizedDescriptionKey: "下载IPA失败"])
        }
        
        try data.write(to: URL(fileURLWithPath: localPath))
        addLog("[INFO] IPA文件下载完成: \(localPath)")
    }
    
    // 上传签名后的IPA文件
    private func uploadSignedIPA(_ localURL: URL) async throws -> String {
        let uploadURL = config.serverBaseURL.appendingPathComponent("api/ipa/upload")
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let data = try createMultipartBody(fileURL: localURL, boundary: boundary)
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Upload", code: 1, userInfo: [NSLocalizedDescriptionKey: "上传IPA失败"])
        }
        
        struct UploadResponse: Codable {
            let downloadURL: String
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        addLog("[INFO] IPA文件上传完成: \(uploadResponse.downloadURL)")
        return uploadResponse.downloadURL
    }
    
    private func createMultipartBody(fileURL: URL, boundary: String) throws -> Data {
        var body = Data()
        
        let fileName = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // MARK: - 本地签名功能
    
    func signLocalIPA(ipaPath: String, bundleId: String, developerId: String, uuid: String) async throws -> SignResult {
        addLog("[INFO] 开始本地IPA签名...")
        addLog("[INFO] IPA路径: \(ipaPath)")
        addLog("[INFO] Bundle ID: \(bundleId)")
        addLog("[INFO] Developer ID: \(developerId)")
        addLog("[INFO] Device UUID: \(uuid)")
        
        // 验证文件存在
        guard FileManager.default.fileExists(atPath: ipaPath) else {
            throw NSError(domain: "LocalSign", code: 1, userInfo: [NSLocalizedDescriptionKey: "IPA文件不存在"])
        }
        
        // 验证凭证
        guard let credential = currentCredential else {
            throw NSError(domain: "LocalSign", code: 2, userInfo: [NSLocalizedDescriptionKey: "未找到Apple ID凭证，请先在设置中配置"])
        }
        
        do {
            // 确保登录
            try await executor.ensureLogin(credential: credential)
            addLog("[INFO] 凭证验证成功")
            
            // 注册设备
            addLog("[INFO] 注册设备UUID: \(uuid)")
            try await executor.registerUDID(uuid, bundleId: bundleId)
            
            // 创建签名选项
            let resignOptions = ResignOptions(
                provisioningProfileId: nil, // 使用默认的
                teamId: nil, // 使用默认的
                newBundleId: bundleId
            )
            
            // 执行重签名
            addLog("[INFO] 开始重签名...")
            let outputURL = try await executor.resignLocalIPA(ipaPath: ipaPath, options: resignOptions)
            
            addLog("[INFO] 签名完成: \(outputURL.path)")
            
            return SignResult(
                success: true,
                message: "签名成功完成",
                outputPath: outputURL.path
            )
            
        } catch {
            addLog("[ERROR] 本地签名失败: \(error)")
            return SignResult(
                success: false,
                message: error.localizedDescription,
                outputPath: nil
            )
        }
    }
    
    // MARK: - 文件上传功能
    
    func uploadFile(filePath: String, uploadURL: String) async throws -> UploadResult {
        addLog("[INFO] 开始上传文件...")
        addLog("[INFO] 文件路径: \(filePath)")
        addLog("[INFO] 上传URL: \(uploadURL)")
        
        // 验证文件存在
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw NSError(domain: "Upload", code: 1, userInfo: [NSLocalizedDescriptionKey: "文件不存在"])
        }
        
        // 验证URL
        guard let url = URL(string: uploadURL) else {
            throw NSError(domain: "Upload", code: 2, userInfo: [NSLocalizedDescriptionKey: "无效的上传URL"])
        }
        
        do {
            // 创建multipart/form-data请求
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let fileURL = URL(fileURLWithPath: filePath)
            let data = try createMultipartBody(fileURL: fileURL, boundary: boundary)
            request.httpBody = data
            
            // 执行上传
            addLog("[INFO] 正在上传文件...")
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Upload", code: 3, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
            }
            
            if httpResponse.statusCode == 200 {
                // 尝试解析响应获取下载链接
                let responseString = String(data: responseData, encoding: .utf8) ?? ""
                addLog("[INFO] 上传成功，响应: \(responseString)")
                
                // 尝试从响应中提取下载链接
                let downloadURL = extractDownloadURL(from: responseString, baseURL: uploadURL)
                
                return UploadResult(
                    success: true,
                    message: "文件上传成功",
                    downloadURL: downloadURL
                )
            } else {
                let errorMessage = "上传失败，状态码: \(httpResponse.statusCode)"
                addLog("[ERROR] \(errorMessage)")
                return UploadResult(
                    success: false,
                    message: errorMessage,
                    downloadURL: nil
                )
            }
            
        } catch {
            addLog("[ERROR] 上传失败: \(error)")
            return UploadResult(
                success: false,
                message: error.localizedDescription,
                downloadURL: nil
            )
        }
    }
    
    private func extractDownloadURL(from response: String, baseURL: String) -> String? {
        // 尝试从响应中提取下载链接
        // 这里可以根据你的服务器响应格式进行调整
        
        // 方法1: 查找JSON中的downloadURL字段
        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let downloadURL = json["downloadURL"] as? String {
            return downloadURL
        }
        
        // 方法2: 查找JSON中的url字段
        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let downloadURL = json["url"] as? String {
            return downloadURL
        }
        
        // 方法3: 查找JSON中的file字段
        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let downloadURL = json["file"] as? String {
            return downloadURL
        }
        
        // 方法4: 如果响应直接是URL
        if response.hasPrefix("http://") || response.hasPrefix("https://") {
            return response
        }
        
        // 方法5: 基于baseURL构造可能的下载链接
        if let baseURL = URL(string: baseURL) {
            let fileName = URL(fileURLWithPath: baseURL.path).lastPathComponent
            return baseURL.appendingPathComponent("download/\(fileName)").absoluteString
        }
        
        return nil
    }
    
    // MARK: - 开发者证书管理
    
    func getInstalledCertificates() async -> [DeveloperCertificate] {
        addLog("[INFO] ========== 开始获取已安装的开发者证书 ==========")
        
        do {
            // 使用security命令获取证书列表
            addLog("[INFO] 执行命令: /usr/bin/security find-identity -v -p codesigning")
            let result = try ProcessRunner.run("/usr/bin/security", ["find-identity", "-v", "-p", "codesigning"], env: [:], cwd: nil) { _ in }
            
            // 添加完整的输出日志
            addLog("[DEBUG] ========== Security命令输出 ==========")
            addLog("[DEBUG] 标准输出长度: \(result.stdout.count) 字符")
            addLog("[DEBUG] 错误输出长度: \(result.stderr.count) 字符")
            addLog("[DEBUG] 完整输出:\n\(result.stdout)")
            if !result.stderr.isEmpty {
                addLog("[DEBUG] 错误输出:\n\(result.stderr)")
            }
            addLog("[DEBUG] ========================================")
            
            var certificates: [DeveloperCertificate] = []
            let lines = result.stdout.components(separatedBy: .newlines)
            
            addLog("[INFO] 原始输出总行数: \(lines.count)")
            addLog("[DEBUG] ========== 逐行分析 ==========")
            for (index, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if !trimmedLine.isEmpty {
                    addLog("[DEBUG] 行 \(index): [\(trimmedLine)]")
                }
            }
            addLog("[DEBUG] ==================================")
            
            // 先收集所有证书
            var allCertificates: [DeveloperCertificate] = []
            var processedLines = 0
            var matchedLines = 0
            var skippedLines = 0
            
            addLog("[INFO] ========== 开始解析证书 ==========")
            
            for (lineIndex, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                // 跳过空行
                if trimmedLine.isEmpty {
                    continue
                }
                
                processedLines += 1
                
                // 更宽松的匹配条件，包含更多证书类型
                // 注意：要匹配"Developer"和"Development"
                if line.contains("Developer") || line.contains("Development") || line.contains("Distribution") {
                    matchedLines += 1
                    addLog("[INFO] ========== 找到证书行 #\(matchedLines) (原始行号: \(lineIndex)) ==========")
                    addLog("[DEBUG] 原始行内容: [\(line)]")
                    
                    // 解析证书信息
                    let components = line.components(separatedBy: "\"")
                    addLog("[DEBUG] 引号分割后组件数量: \(components.count)")
                    
                    for (index, component) in components.enumerated() {
                        addLog("[DEBUG]   组件[\(index)]: [\(component)]")
                    }
                    
                    if components.count >= 2 {
                        // 重新分析security输出格式
                        // 格式: "1) CERTIFICATE_ID "CERTIFICATE_NAME""
                        // 用引号分割后: [0]="1) CERTIFICATE_ID ", [1]="CERTIFICATE_NAME", [2]=""
                        
                        // 从第0个组件提取证书ID（去掉前面的数字和括号）
                        let firstPart = components[0].trimmingCharacters(in: .whitespaces)
                        addLog("[DEBUG] 第一部分(去空格): [\(firstPart)]")
                        
                        let idParts = firstPart.components(separatedBy: ") ")
                        addLog("[DEBUG] 按') '分割后: \(idParts.count) 部分")
                        for (idx, part) in idParts.enumerated() {
                            addLog("[DEBUG]   ID部分[\(idx)]: [\(part)]")
                        }
                        
                        let certificateId = idParts.last?.trimmingCharacters(in: .whitespaces) ?? firstPart
                        
                        // 证书名称在components[1]中
                        let displayName = components[1].trimmingCharacters(in: .whitespaces)
                        
                        addLog("[INFO] ✓ 提取成功:")
                        addLog("[INFO]   证书ID: [\(certificateId)]")
                        addLog("[INFO]   显示名称: [\(displayName)]")
                        
                        let certType = getCertificateType(from: line)
                        let certificate = DeveloperCertificate(
                            id: certificateId,
                            name: displayName,
                            type: certType
                        )
                        
                        addLog("[INFO]   证书类型: \(certType.displayName)")
                        addLog("[INFO]   完整显示: [\(certificate.displayName)]")
                        addLog("[INFO]   是否为Development: \(certType.isDevelopment)")
                        
                        allCertificates.append(certificate)
                        addLog("[SUCCESS] 证书 #\(allCertificates.count) 添加成功")
                    } else {
                        skippedLines += 1
                        addLog("[WARN] ✗ 组件数量不足(\(components.count))，跳过此行")
                    }
                    addLog("[INFO] ==========================================")
                } else {
                    // 不匹配的行
                    if !trimmedLine.isEmpty && !trimmedLine.contains("valid identities found") {
                        addLog("[DEBUG] 跳过非证书行 #\(lineIndex): [\(trimmedLine)]")
                    }
                }
            }
            
            addLog("[INFO] ========== 解析统计 ==========")
            addLog("[INFO] 处理的非空行数: \(processedLines)")
            addLog("[INFO] 匹配的证书行数: \(matchedLines)")
            addLog("[INFO] 跳过的行数: \(skippedLines)")
            addLog("[INFO] 成功解析的证书数: \(allCertificates.count)")
            addLog("[INFO] ==================================")
            
            addLog("[INFO] ========== 开始证书排序 ==========")
            addLog("[INFO] 排序前证书列表:")
            for (index, cert) in allCertificates.enumerated() {
                addLog("[INFO]   [\(index+1)] \(cert.type.displayName): \(cert.shortDisplayName)")
            }
            
            // 按优先级排序：Development证书优先，然后按类型排序
            certificates = allCertificates.sorted { cert1, cert2 in
                // Development证书优先
                if cert1.type.isDevelopment && !cert2.type.isDevelopment {
                    return true // cert1是Development，cert2不是，cert1优先
                } else if !cert1.type.isDevelopment && cert2.type.isDevelopment {
                    return false // cert2是Development，cert1不是，cert2优先
                } else {
                    // 都是Development或都不是，按类型排序
                    return cert1.type.rawValue < cert2.type.rawValue
                }
            }
            
            addLog("[INFO] 排序后证书列表 (Development优先):")
            for (index, cert) in certificates.enumerated() {
                addLog("[INFO]   [\(index+1)] \(cert.type.displayName): \(cert.shortDisplayName) [isDev: \(cert.type.isDevelopment)]")
            }
            addLog("[INFO] ==================================")
            
            addLog("[SUCCESS] ========== 证书获取完成 ==========")
            addLog("[SUCCESS] 总共找到 \(certificates.count) 个开发者证书")
            addLog("[SUCCESS] ======================================")
            
            return certificates
            
        } catch {
            addLog("[ERROR] 获取证书失败: \(error)")
            return []
        }
    }
    
    private func getCertificateType(from line: String) -> CertificateType {
        addLog("[DEBUG] 检测证书类型，行内容: [\(line)]")
        
        // 注意：要先检查Distribution，因为"Apple Distribution"也包含"Distribution"
        if line.contains("Apple Distribution") {
            addLog("[DEBUG] ✓ 检测到Apple Distribution")
            return .appleDistribution
        } else if line.contains("iOS Distribution") {
            addLog("[DEBUG] ✓ 检测到iOS Distribution")
            return .iosDistribution
        } else if line.contains("Mac Distribution") {
            addLog("[DEBUG] ✓ 检测到Mac Distribution")
            return .macDistribution
        } else if line.contains("Apple Development") {
            addLog("[DEBUG] ✓ 检测到Apple Development")
            return .appleDevelopment
        } else if line.contains("iPhone Developer") {
            addLog("[DEBUG] ✓ 检测到iPhone Developer")
            return .iosDevelopment
        } else if line.contains("Mac Developer") {
            addLog("[DEBUG] ✓ 检测到Mac Developer")
            return .macDevelopment
        } else {
            addLog("[WARN] ✗ 未识别的证书类型，返回unknown")
            return .unknown
        }
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}