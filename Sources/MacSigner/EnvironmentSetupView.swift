import SwiftUI
import AppKit

struct EnvironmentSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var pathResolver = ProjectPathResolver()
    @State private var isInstalling = false
    @State private var installState: InstallState = .idle
    @State private var installOutput = ""
    @State private var installError: String?
    
    private enum InstallState {
        case idle
        case running
        case success
        case failed
    }
    
    private struct SetupStep: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let command: String?
    }
    
    private struct AutoInstallCommand {
        let title: String
        let command: String
        let workingDirectory: URL?
    }
    
    private struct ProjectPathResolver: Equatable {
        let projectRoot: URL?
        let fastlaneRoot: URL?
        let errors: [String]
        
        init() {
            let fm = FileManager.default
            var notes: [String] = []
            let candidates = ProjectPathResolver.buildCandidates()
            var foundRoot: URL?
            for candidate in candidates {
                if let root = ProjectPathResolver.findPackageRoot(startingAt: candidate, fileManager: fm) {
                    foundRoot = root
                    break
                }
            }
            if foundRoot == nil {
                notes.append("未能在候选路径中找到 Package.swift")
            }
            projectRoot = foundRoot
            if let root = foundRoot {
                let fastlanePath = root.appendingPathComponent("fastlane", isDirectory: true)
                if fm.fileExists(atPath: fastlanePath.path) {
                    fastlaneRoot = fastlanePath
                } else {
                    fastlaneRoot = nil
                    notes.append("在 \(root.path) 未找到 fastlane 目录")
                }
            } else {
                fastlaneRoot = nil
            }
            errors = notes
        }
        
        private static func buildCandidates() -> [URL] {
            var raw: [URL] = []
            let fm = FileManager.default
            raw.append(URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true))
            if let pwd = ProcessInfo.processInfo.environment["PWD"] {
                raw.append(URL(fileURLWithPath: pwd, isDirectory: true))
            }
            let bundleURL = Bundle.main.bundleURL
            raw.append(bundleURL)
            raw.append(bundleURL.deletingLastPathComponent())
            var sourceURL = URL(fileURLWithPath: #filePath)
            sourceURL.deleteLastPathComponent() // EnvironmentSetupView.swift -> Sources/MacSigner
            sourceURL.deleteLastPathComponent() // Sources/MacSigner -> Sources
            sourceURL.deleteLastPathComponent() // Sources -> project root
            raw.append(sourceURL)
            var unique: [URL] = []
            var seen = Set<String>()
            for url in raw {
                let path = url.standardizedFileURL.path
                if !seen.contains(path) {
                    unique.append(url.standardizedFileURL)
                    seen.insert(path)
                }
            }
            return unique
        }
        
        private static func findPackageRoot(startingAt start: URL, fileManager: FileManager) -> URL? {
            var isDir: ObjCBool = false
            var current = start
            if !fileManager.fileExists(atPath: current.path, isDirectory: &isDir) {
                return nil
            }
            if !isDir.boolValue {
                current.deleteLastPathComponent()
            }
            let rootPath = URL(fileURLWithPath: "/", isDirectory: true).path
            while current.path != rootPath {
                let target = current.appendingPathComponent("Package.swift")
                if fileManager.fileExists(atPath: target.path) {
                    return current
                }
                let parent = current.deletingLastPathComponent()
                if parent.path == current.path { break }
                current = parent
            }
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    autoInstallSection
                    manualSection
                }
                .padding()
            }
            Divider()
            footer
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear { refreshPaths() }
    }
    
    private var header: some View {
        HStack {
            Text("环境安装指南")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button("刷新路径") { refreshPaths() }
                .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var footer: some View {
        HStack {
            Spacer()
            Button("关闭") { dismiss() }
                .buttonStyle(.bordered)
                .frame(width: 80)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var autoInstallSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("一键安装环境")
                .font(.headline)
            Text("自动执行依赖安装脚本。如果失败，可以通过下方命令手动执行。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let root = pathResolver.projectRoot {
                Text("检测到项目路径: \(root.path)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            } else {
                Text("未能自动定位项目路径，请确认 Package.swift 所在目录。")
                    .font(.footnote)
                    .foregroundColor(.orange)
            }
            if !pathResolver.errors.isEmpty {
                ForEach(pathResolver.errors, id: \.self) { message in
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            }
            HStack(spacing: 12) {
                Button(action: runAutoInstall) {
                    Text(isInstalling ? "安装中..." : "开始安装")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling)
                
                if isInstalling {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    statusIndicator
                }
            }
            if let error = installError, installState == .failed {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            if !installOutput.isEmpty {
                ScrollView {
                    Text(installOutput)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 220)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("手动安装步骤")
                .font(.headline)
            ForEach(setupSteps(resolver: pathResolver)) { step in
                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(step.detail)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    if let command = step.command {
                        HStack(alignment: .top, spacing: 8) {
                            Text(command)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                copyToClipboard(command)
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
                .cornerRadius(6)
            }
        }
    }
    
    private var statusIndicator: some View {
        Group {
            switch installState {
            case .idle, .running:
                EmptyView()
            case .success:
                Label("安装完成", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.footnote)
            case .failed:
                Label("安装失败", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.footnote)
            }
        }
    }
    
    private func setupSteps(resolver: ProjectPathResolver) -> [SetupStep] {
        guard let projectRoot = resolver.projectRoot, let fastlaneRoot = resolver.fastlaneRoot else {
            var rows: [SetupStep] = []
            if resolver.projectRoot == nil {
                rows.append(
                    SetupStep(
                        title: "定位项目根目录",
                        detail: "请在终端中切换到包含 Package.swift 的目录后再执行下面的命令。",
                        command: nil
                    )
                )
            }
            if resolver.fastlaneRoot == nil {
                rows.append(
                    SetupStep(
                        title: "检查 fastlane 目录",
                        detail: "确认项目根目录下存在 fastlane 目录，包含 Gemfile。",
                        command: nil
                    )
                )
            }
            return rows
        }
        let rootPath = shellQuote(projectRoot.path)
        let fastlanePath = shellQuote(fastlaneRoot.path)
        return [
            SetupStep(
                title: "更新 Swift 依赖",
                detail: "下载并锁定 Swift 包依赖。",
                command: "cd \(rootPath) && rm -rf .build && swift package clean && swift package resolve"
            ),
            SetupStep(
                title: "安装 Bundler",
                detail: "确保 Ruby Bundler 可用，用于管理 fastlane 依赖。",
                command: "gem install bundler"
            ),
            SetupStep(
                title: "安装 fastlane 依赖",
                detail: "在 fastlane 目录安装 Gemfile 中的依赖。",
                command: "cd \(fastlanePath) && bundle install"
            ),
            SetupStep(
                title: "验证 fastlane",
                detail: "确认 fastlane 可以通过 Bundler 调用。",
                command: "cd \(fastlanePath) && bundle exec fastlane --version"
            )
        ]
    }
    
    private func autoInstallCommands(resolver: ProjectPathResolver) -> [AutoInstallCommand] {
        guard let projectRoot = resolver.projectRoot, let fastlaneRoot = resolver.fastlaneRoot else { return [] }
        return [
            AutoInstallCommand(title: "更新 Swift 依赖", command: "swift package resolve", workingDirectory: projectRoot),
            AutoInstallCommand(title: "安装 Bundler", command: "if ! command -v bundle >/dev/null 2>&1; then gem install bundler; fi", workingDirectory: nil),
            AutoInstallCommand(title: "安装 fastlane 依赖", command: "bundle install", workingDirectory: fastlaneRoot),
            AutoInstallCommand(title: "验证 fastlane", command: "bundle exec fastlane --version", workingDirectory: fastlaneRoot)
        ]
    }
    
    private func refreshPaths() {
        pathResolver = ProjectPathResolver()
    }
    
    private func runAutoInstall() {
        guard !isInstalling else { return }
        let resolver = pathResolver
        guard let projectRoot = resolver.projectRoot else {
            installState = .failed
            installError = "未能定位项目根目录 (缺少 Package.swift)"
            return
        }
        guard let fastlaneRoot = resolver.fastlaneRoot, FileManager.default.fileExists(atPath: fastlaneRoot.path) else {
            installState = .failed
            installError = "fastlane 目录不存在"
            return
        }
        installOutput = "项目目录: \(projectRoot.path)\n"
        installError = nil
        installState = .running
        isInstalling = true
        let commands = autoInstallCommands(resolver: resolver)
        if commands.isEmpty {
            installState = .failed
            installError = "安装命令为空，请检查项目路径"
            isInstalling = false
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                for command in commands {
                    DispatchQueue.main.async {
                            self.installOutput.append("\n▶︎ \(command.title)\n$ \(command.command)\n")
                    }
                    let result = try ProcessRunner.run(
                        "/bin/bash",
                        ["-lc", command.command],
                        cwd: command.workingDirectory,
                        tee: { chunk in
                            DispatchQueue.main.async {
                                    self.installOutput.append(chunk)
                            }
                        }
                    )
                    guard result.exitCode == 0 else {
                        let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                        throw NSError(
                            domain: "AutoInstall",
                            code: Int(result.exitCode),
                            userInfo: [NSLocalizedDescriptionKey: stderr.isEmpty ? "命令执行失败" : stderr]
                        )
                    }
                }
                DispatchQueue.main.async {
                    self.installState = .success
                    self.isInstalling = false
                    self.installOutput.append("\n完成 ✅\n")
                    self.refreshPaths()
                }
            } catch {
                DispatchQueue.main.async {
                    self.installState = .failed
                    self.installError = error.localizedDescription
                    self.isInstalling = false
                }
            }
        }
    }
    
    private func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
    
    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
