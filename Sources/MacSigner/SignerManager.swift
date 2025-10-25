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
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}