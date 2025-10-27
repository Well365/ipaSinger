import SwiftUI

struct AppleAPIConfigView: View {
    @State private var keyID = ""
    @State private var issuerID = ""
    @State private var privateKey = ""
    @State private var showingFileImporter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isTestingConnection = false
    @State private var testResult: TestResult?
    @StateObject private var configManager = AppleAPIConfigManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Apple Developer API 配置")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("使用Apple Developer API替代FastLane认证，避免应用专用密码问题")
                .foregroundColor(.secondary)
            
            Divider()
            
            // Key ID输入
            VStack(alignment: .leading, spacing: 8) {
                Text("Key ID")
                    .fontWeight(.medium)
                TextField("例如: ABCDEF1234", text: $keyID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("在App Store Connect的API密钥页面可以找到")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Issuer ID输入
            VStack(alignment: .leading, spacing: 8) {
                Text("Issuer ID")
                    .fontWeight(.medium)
                TextField("例如: 57246542-96fe-1a63-e053-0824d011072a", text: $issuerID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("团队的Issuer ID，在API密钥页面顶部显示")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 私钥输入
            VStack(alignment: .leading, spacing: 8) {
                Text("私钥 (.p8文件内容)")
                    .fontWeight(.medium)
                
                HStack {
                    Button("选择.p8文件") {
                        showingFileImporter = true
                    }
                    .buttonStyle(.bordered)
                    
                    if !privateKey.isEmpty {
                        Text("✅ 私钥已加载")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                ScrollView {
                    TextEditor(text: $privateKey)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 100, maxHeight: 200)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text("将下载的.p8文件内容完整粘贴到此处")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 操作按钮
            HStack {
                Button("获取API密钥帮助") {
                    showAPIKeyHelp()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("测试配置") {
                    testConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyID.isEmpty || issuerID.isEmpty || privateKey.isEmpty || isTestingConnection)
                
                Button("保存配置") {
                    saveConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyID.isEmpty || issuerID.isEmpty || privateKey.isEmpty)
                
                if isTestingConnection {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("正在测试连接...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 测试结果显示
            if let result = testResult {
                TestResultView(result: result)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 700, height: 600)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadSavedConfiguration()
        }
    }
    
    private func showAPIKeyHelp() {
        let helpMessage = """
        获取Apple Developer API密钥的步骤：
        
        1. 访问 App Store Connect
        2. 点击右上角用户菜单 → 密钥
        3. 在API密钥标签页中点击 "生成API密钥"
        4. 填写密钥名称，选择访问权限（至少需要开发者权限）
        5. 点击生成，记录Key ID
        6. 下载.p8文件
        7. 复制页面顶部的Issuer ID
        
        注意：.p8文件只能下载一次，请妥善保存
        """
        
        alertMessage = helpMessage
        showingAlert = true
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let content = try String(contentsOf: url)
                privateKey = content
                alertMessage = "私钥文件加载成功！"
                showingAlert = true
            } catch {
                alertMessage = "读取文件失败: \(error.localizedDescription)"
                showingAlert = true
            }
            
        case .failure(let error):
            alertMessage = "选择文件失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func testConfiguration() {
        // 基础验证
        guard !keyID.isEmpty, !issuerID.isEmpty, !privateKey.isEmpty else {
            alertMessage = "请填写所有必要信息"
            showingAlert = true
            return
        }
        
        // 验证Key ID格式
        guard keyID.count == 10, keyID.allSatisfy({ $0.isUppercase || $0.isNumber }) else {
            alertMessage = "Key ID格式不正确，应为10位大写字母和数字"
            showingAlert = true
            return
        }
        
        // 验证Issuer ID格式（UUID）
        guard UUID(uuidString: issuerID) != nil else {
            alertMessage = "Issuer ID格式不正确，应为UUID格式"
            showingAlert = true
            return
        }
        
        // 验证私钥格式
        guard privateKey.contains("-----BEGIN PRIVATE KEY-----") && 
              privateKey.contains("-----END PRIVATE KEY-----") else {
            alertMessage = "私钥格式不正确，应包含PEM格式的头部和尾部"
            showingAlert = true
            return
        }
        
        // 开始API连接测试
        isTestingConnection = true
        testResult = nil
        
        Task {
            let result = await configManager.testConnection(
                keyID: keyID,
                issuerID: issuerID,
                privateKey: privateKey
            )
            
            await MainActor.run {
                testResult = result
                isTestingConnection = false
                
                if result.success {
                    alertMessage = "✅ 连接测试成功！API配置正确。"
                } else {
                    alertMessage = "❌ 连接测试失败: \(result.message)"
                }
                showingAlert = true
            }
        }
    }
    
    private func testAPIConnection() async {
        // 这个方法现在被testConfiguration()替代
        // 保留以避免编译错误
    }
    
    private func saveConfiguration() {
        // 保存到环境变量（临时方案）
        // 在实际应用中，应该保存到Keychain或安全存储
        setenv("APPLE_API_KEY_ID", keyID, 1)
        setenv("APPLE_API_ISSUER_ID", issuerID, 1)
        setenv("APPLE_API_PRIVATE_KEY", privateKey, 1)
        
        // 也可以保存到UserDefaults（仅用于开发测试）
        UserDefaults.standard.set(keyID, forKey: "AppleAPIKeyID")
        UserDefaults.standard.set(issuerID, forKey: "AppleAPIIssuerID")
        UserDefaults.standard.set(privateKey, forKey: "AppleAPIPrivateKey")
        
        alertMessage = "配置已保存！现在可以使用Apple API进行设备注册和签名"
        showingAlert = true
    }
    
    private func loadSavedConfiguration() {
        // 从UserDefaults加载保存的配置
        keyID = UserDefaults.standard.string(forKey: "AppleAPIKeyID") ?? ""
        issuerID = UserDefaults.standard.string(forKey: "AppleAPIIssuerID") ?? ""
        privateKey = UserDefaults.standard.string(forKey: "AppleAPIPrivateKey") ?? ""
    }
}

// MARK: - 数据模型
struct TestResult {
    let success: Bool
    let message: String
    let details: [String]?
}

// MARK: - 测试结果视图
struct TestResultView: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                    .font(.title2)
                
                Text(result.success ? "连接测试成功" : "连接测试失败")
                    .font(.headline)
                    .foregroundColor(result.success ? .green : .red)
            }
            
            Text(result.message)
                .font(.body)
                .foregroundColor(.secondary)
            
            if let details = result.details {
                VStack(alignment: .leading, spacing: 4) {
                    Text("详细信息:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(details, id: \.self) { detail in
                        Text("• \(detail)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 配置管理器
class AppleAPIConfigManager: ObservableObject {
    func saveConfig(keyID: String, issuerID: String, privateKey: String) {
        UserDefaults.standard.set(keyID, forKey: "appleAPIKeyID")
        UserDefaults.standard.set(issuerID, forKey: "appleAPIIssuerID")
        UserDefaults.standard.set(privateKey, forKey: "appleAPIPrivateKey")
    }
    
    func testConnection(keyID: String, issuerID: String, privateKey: String) async -> TestResult {
        do {
            let api = AppleDeveloperAPI(keyID: keyID, issuerID: issuerID, privateKey: privateKey)
            
            // 首先验证配置
            try api.validateConfiguration()
            
            // 测试JWT生成
            let jwt = try api.testJWTGeneration()
            
            // 测试API连接
            try await api.testAPIConnection()
            
            return TestResult(
                success: true,
                message: "所有测试通过！API配置正确，可以正常使用设备管理功能。",
                details: [
                    "✅ 配置验证通过",
                    "✅ JWT生成成功",
                    "✅ API连接成功",
                    "🔗 JWT长度: \(jwt.count) 字符"
                ]
            )
            
        } catch {
            return TestResult(
                success: false,
                message: "测试失败: \(error.localizedDescription)",
                details: [
                    "❌ 错误类型: \(type(of: error))",
                    "💡 请检查配置是否正确",
                    "💡 确保网络连接正常"
                ]
            )
        }
    }
}

// MARK: - 预览
struct AppleAPIConfigView_Previews: PreviewProvider {
    static var previews: some View {
        AppleAPIConfigView()
    }
}