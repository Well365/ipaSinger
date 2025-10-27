import Foundation
import SwiftUI

// MARK: - Apple API签名执行器
class AppleAPISignExecutor: ObservableObject {
    @Published var isProcessing = false
    @Published var progress = ""
    @Published var logs: [String] = []
    
    private let config: Config
    private var api: AppleDeveloperAPI?
    
    init(config: Config) {
        self.config = config
    }
    
    private func setupAPI() throws {
        guard !config.appleAPIKeyID.isEmpty,
              !config.appleAPIIssuerID.isEmpty,
              !config.appleAPIPrivateKey.isEmpty else {
            throw AppleAPISignError.missingAPICredentials
        }
        
        api = AppleDeveloperAPI(
            keyID: config.appleAPIKeyID,
            issuerID: config.appleAPIIssuerID,
            privateKey: config.appleAPIPrivateKey
        )
    }
    
    // MARK: - 主要签名流程
    func resignIPA(ipaPath: String, udid: String, bundleID: String) async {
        await MainActor.run {
            isProcessing = true
            progress = "开始重新签名..."
            logs = []
        }
        
        do {
            try setupAPI()
            guard let api = api else { throw AppleAPISignError.apiNotInitialized }
            
            // 步骤1: 注册设备
            await updateProgress("步骤1: 检查设备注册状态...")
            let device = try await registerDeviceIfNeeded(api: api, udid: udid)
            await addLog("✅ 设备已注册: \(device.attributes.name)")
            
            // 步骤2: 获取证书
            await updateProgress("步骤2: 获取开发证书...")
            let certificate = try await getDevelopmentCertificate(api: api)
            await addLog("✅ 找到证书: \(certificate.attributes.name)")
            
            // 步骤3: 获取或创建Bundle ID
            await updateProgress("步骤3: 检查Bundle ID...")
            let bundleId = try await getBundleId(api: api, identifier: bundleID)
            await addLog("✅ Bundle ID: \(bundleId.attributes.identifier)")
            
            // 步骤4: 获取或创建Provisioning Profile
            await updateProgress("步骤4: 获取Provisioning Profile...")
            let profile = try await getOrCreateProvisioningProfile(
                api: api,
                bundleId: bundleId,
                certificate: certificate,
                device: device
            )
            await addLog("✅ Provisioning Profile: \(profile.attributes.name)")
            
            // 步骤5: 下载并保存Provisioning Profile
            await updateProgress("步骤5: 下载Provisioning Profile...")
            let profilePath = try await downloadProvisioningProfile(profile: profile)
            await addLog("✅ Profile已保存到: \(profilePath)")
            
            // 步骤6: 重新签名IPA
            await updateProgress("步骤6: 重新签名IPA...")
            let signedIPA = try await resignIPAFile(
                ipaPath: ipaPath,
                profilePath: profilePath,
                certificate: certificate
            )
            await addLog("✅ IPA重新签名完成: \(signedIPA)")
            
            await updateProgress("✅ 重新签名完成！")
            await addLog("🎉 所有步骤完成，IPA已准备好安装")
            
        } catch {
            await addLog("❌ 错误: \(error.localizedDescription)")
            await updateProgress("❌ 签名失败")
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    // MARK: - 辅助方法
    private func updateProgress(_ message: String) async {
        await MainActor.run {
            progress = message
        }
        await addLog(message)
    }
    
    private func addLog(_ message: String) async {
        let timestamp = DateFormatter.appleAPILogFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        await MainActor.run {
            logs.append(logMessage)
        }
        
        print(logMessage)
    }
    
    // MARK: - 设备注册
    private func registerDeviceIfNeeded(api: AppleDeveloperAPI, udid: String) async throws -> Device {
        // 先检查设备是否已存在
        if let existingDevice = try await api.findDevice(udid: udid) {
            await addLog("设备已存在，跳过注册")
            return existingDevice
        }
        
        // 注册新设备
        await addLog("注册新设备...")
        let deviceName = "Device-\(udid.suffix(8))"
        return try await api.registerDevice(udid: udid, name: deviceName)
    }
    
    // MARK: - 证书获取
    private func getDevelopmentCertificate(api: AppleDeveloperAPI) async throws -> AppleCertificate {
        let certificates = try await api.listCertificates(type: AppleCertificateType.development)
        
        guard let certificate = certificates.first else {
            throw AppleAPISignError.noCertificateFound
        }
        
        await addLog("找到开发证书: \(certificate.attributes.displayName)")
        return certificate
    }
    
    // MARK: - Bundle ID获取
    private func getBundleId(api: AppleDeveloperAPI, identifier: String) async throws -> BundleId {
        if let bundleId = try await api.findBundleId(identifier: identifier) {
            return bundleId
        }
        
        throw AppleAPISignError.bundleIdNotFound(identifier)
    }
    
    // MARK: - Provisioning Profile管理
    private func getOrCreateProvisioningProfile(
        api: AppleDeveloperAPI,
        bundleId: BundleId,
        certificate: AppleCertificate,
        device: Device
    ) async throws -> ProvisioningProfile {
        // 检查现有的Provisioning Profile
        let profiles = try await api.listProvisioningProfiles(bundleId: bundleId.id)
        
        // 寻找包含目标设备的profile
        for profile in profiles {
            if profile.attributes.profileType == ProvisioningProfileType.development {
                await addLog("找到现有开发Profile: \(profile.attributes.name)")
                return profile
            }
        }
        
        // 创建新的Provisioning Profile
        await addLog("创建新的Provisioning Profile...")
        let profileName = "Dev-\(bundleId.attributes.identifier)-\(Date().timeIntervalSince1970)"
        
        return try await api.createProvisioningProfile(
            name: profileName,
            bundleId: bundleId.id,
            certificateIds: [certificate.id],
            deviceIds: [device.id],
            profileType: ProvisioningProfileType.development
        )
    }
    
    // MARK: - Provisioning Profile下载
    private func downloadProvisioningProfile(profile: ProvisioningProfile) async throws -> String {
        // 解码Base64的profile内容
        guard let profileData = Data(base64Encoded: profile.attributes.profileContent) else {
            throw AppleAPISignError.invalidProfileContent
        }
        
        // 保存到临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let profilePath = tempDir.appendingPathComponent("\(profile.attributes.uuid).mobileprovision").path
        
        try profileData.write(to: URL(fileURLWithPath: profilePath))
        
        await addLog("Profile已下载到: \(profilePath)")
        return profilePath
    }
    
    // MARK: - IPA重新签名
    private func resignIPAFile(
        ipaPath: String,
        profilePath: String,
        certificate: AppleCertificate
    ) async throws -> String {
        let workDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        
        let payloadDir = workDir.appendingPathComponent("Payload")
        
        do {
            // 1. 解压IPA
            await addLog("解压IPA文件...")
            try await runCommand("unzip", args: ["-q", ipaPath, "-d", workDir.path])
            
            // 2. 找到app文件
            let appDirs = try FileManager.default.contentsOfDirectory(atPath: payloadDir.path)
                .filter { $0.hasSuffix(".app") }
            
            guard let appDir = appDirs.first else {
                throw AppleAPISignError.appNotFound
            }
            
            let appPath = payloadDir.appendingPathComponent(appDir).path
            await addLog("找到应用: \(appDir)")
            
            // 3. 替换Provisioning Profile
            await addLog("替换Provisioning Profile...")
            let embeddedProfilePath = "\(appPath)/embedded.mobileprovision"
            try FileManager.default.copyItem(atPath: profilePath, toPath: embeddedProfilePath)
            
            // 4. 重新签名
            await addLog("开始重新签名...")
            let signingIdentity = certificate.attributes.name
            
            // 签名所有framework
            await addLog("签名Frameworks...")
            let frameworksPath = "\(appPath)/Frameworks"
            if FileManager.default.fileExists(atPath: frameworksPath) {
                let frameworks = try FileManager.default.contentsOfDirectory(atPath: frameworksPath)
                for framework in frameworks {
                    let frameworkPath = "\(frameworksPath)/\(framework)"
                    try await signFile(frameworkPath, identity: signingIdentity)
                }
            }
            
            // 签名主应用
            await addLog("签名主应用...")
            try await signFile(appPath, identity: signingIdentity, entitlements: nil)
            
            // 5. 重新打包
            await addLog("重新打包IPA...")
            let resignedIPAPath = ipaPath.replacingOccurrences(of: ".ipa", with: "-resigned.ipa")
            
            let currentDir = FileManager.default.currentDirectoryPath
            FileManager.default.changeCurrentDirectoryPath(workDir.path)
            
            try await runCommand("zip", args: ["-r", resignedIPAPath, "Payload"])
            
            FileManager.default.changeCurrentDirectoryPath(currentDir)
            
            // 清理临时文件
            try FileManager.default.removeItem(at: workDir)
            
            return resignedIPAPath
            
        } catch {
            // 清理临时文件
            try? FileManager.default.removeItem(at: workDir)
            throw error
        }
    }
    
    private func signFile(_ path: String, identity: String, entitlements: String? = nil) async throws {
        var args = ["--force", "--sign", identity]
        
        if let entitlements = entitlements {
            args.append(contentsOf: ["--entitlements", entitlements])
        }
        
        args.append(path)
        
        try await runCommand("codesign", args: args)
    }
    
    private func runCommand(_ command: String, args: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/\(command)")
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppleAPISignError.commandFailed("\(command) failed: \(output)")
        }
    }
}

// MARK: - 错误定义
enum AppleAPISignError: LocalizedError {
    case missingAPICredentials
    case apiNotInitialized
    case noCertificateFound
    case bundleIdNotFound(String)
    case invalidProfileContent
    case appNotFound
    case commandFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPICredentials:
            return "Apple API凭据不完整"
        case .apiNotInitialized:
            return "API未初始化"
        case .noCertificateFound:
            return "未找到开发证书"
        case .bundleIdNotFound(let identifier):
            return "未找到Bundle ID: \(identifier)"
        case .invalidProfileContent:
            return "无效的Provisioning Profile内容"
        case .appNotFound:
            return "在IPA中未找到应用程序"
        case .commandFailed(let message):
            return "命令执行失败: \(message)"
        }
    }
}

// MARK: - 日期格式化
extension DateFormatter {
    static let appleAPILogFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}