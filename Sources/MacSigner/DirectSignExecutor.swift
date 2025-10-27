import Foundation

/// 直接签名错误类型
enum DirectSignError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidIPA(String)
    case processError(String)
    case signFailed(String)
    case missingOptions
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return "文件未找到: \(message)"
        case .invalidIPA(let message):
            return "无效的IPA: \(message)"
        case .processError(let message):
            return "处理错误: \(message)"
        case .signFailed(let message):
            return "签名失败: \(message)"
        case .missingOptions:
            return "缺少签名选项"
        }
    }
}

/// 简化的签名执行器，使用codesign直接重签名，避免FastLane的复杂性
final class DirectSignExecutor: SignExecutor {
    private let outputDir: URL
    
    init(outputDir: URL) {
        self.outputDir = outputDir
        // 确保输出目录存在
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }
    
    func ensureLogin(credential: LoginCredential) async throws {
        print("[直接签名] 跳过登录验证")
        // 直接签名不需要登录Apple服务器
    }
    
    func registerUDID(_ udid: String, bundleId: String) async throws {
        print("[直接签名] 跳过设备注册")
        // 直接签名不需要注册设备到Apple Developer Portal
    }
    
    func resignIPA(ipaId: String, options: ResignOptions?) async throws -> URL {
        throw SignError.notImplemented
    }
    
    func resignLocalIPA(ipaPath: String, options: ResignOptions?) async throws -> URL {
        guard let options = options else {
            throw DirectSignError.missingOptions
        }
        
        let bundleId = options.newBundleId ?? "com.example.app"
        let signingIdentity = "iPhone Developer" // 可以从 options 或配置中获取
        
        print("[直接签名] 开始重签名IPA")
        print("[直接签名] IPA路径: \(ipaPath)")
        print("[直接签名] Bundle ID: \(bundleId)")
        print("[直接签名] 签名身份: \(signingIdentity)")
        
        // 检查IPA文件是否存在
        guard FileManager.default.fileExists(atPath: ipaPath) else {
            throw DirectSignError.fileNotFound("IPA文件不存在: \(ipaPath)")
        }
        
        // 创建临时工作目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("direct_resign_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // 清理临时目录
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        print("[直接签名] 临时目录: \(tempDir.path)")
        
        // 解压IPA
        print("[直接签名] 解压IPA文件...")
        let unzipResult = try ProcessRunner.run("/usr/bin/unzip", ["-q", ipaPath], cwd: tempDir) { _ in }
        guard unzipResult.exitCode == 0 else {
            throw DirectSignError.processError("解压IPA失败: \(unzipResult.stderr)")
        }
        
        // 查找Payload目录中的.app文件
        let payloadDir = tempDir.appendingPathComponent("Payload")
        guard FileManager.default.fileExists(atPath: payloadDir.path) else {
            throw DirectSignError.invalidIPA("未找到Payload目录")
        }
        
        let appFiles = try FileManager.default.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "app" }
        
        guard let appPath = appFiles.first else {
            throw DirectSignError.invalidIPA("未找到.app文件")
        }
        
        print("[直接签名] 找到App: \(appPath.lastPathComponent)")
        
        // 显示当前签名信息
        print("[直接签名] 检查当前签名...")
        let checkResult = try ProcessRunner.run("/usr/bin/codesign", ["-dvvv", appPath.path], cwd: tempDir) { output in
            print("[直接签名] 当前签名信息: \(output)")
        }
        
        // 重新签名
        print("[直接签名] 开始重新签名...")
        let resignResult = try ProcessRunner.run("/usr/bin/codesign", [
            "--force",
            "--sign", signingIdentity,
            appPath.path
        ], cwd: tempDir) { output in
            print("[直接签名] 签名输出: \(output)")
        }
        
        guard resignResult.exitCode == 0 else {
            throw DirectSignError.signFailed("重签名失败: \(resignResult.stderr)")
        }
        
        print("[直接签名] 签名完成，开始重新打包...")
        
        // 生成输出文件名
        let inputURL = URL(fileURLWithPath: ipaPath)
        let outputFileName = inputURL.deletingPathExtension().lastPathComponent + "_resigned.ipa"
        let outputPath = outputDir.appendingPathComponent(outputFileName)
        
        // 删除已存在的输出文件
        if FileManager.default.fileExists(atPath: outputPath.path) {
            try FileManager.default.removeItem(at: outputPath)
        }
        
        // 重新打包IPA
        let zipResult = try ProcessRunner.run("/usr/bin/zip", [
            "-r",
            outputPath.path,
            "Payload"
        ], cwd: tempDir) { output in
            print("[直接签名] 打包输出: \(output)")
        }
        
        guard zipResult.exitCode == 0 else {
            throw DirectSignError.processError("重新打包失败: \(zipResult.stderr)")
        }
        
        // 验证输出文件
        guard FileManager.default.fileExists(atPath: outputPath.path) else {
            throw DirectSignError.fileNotFound("输出文件未生成")
        }
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputPath.path)[.size] as? Int64) ?? 0
        print("[直接签名] 重签名完成: \(outputPath.path)")
        print("[直接签名] 文件大小: \(fileSize) bytes")
        
        return outputPath
    }
}