import SwiftUI
import AppKit
import UserNotifications
import Combine

struct SessionManagerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var appleId = ""
    @State private var password = ""
    @State private var twoFactorCode = ""
    @State private var authError: String?
    @State private var showingSuccessAlert = false
    @State private var authMode: AuthMode = .appSpecificPassword
    @State private var setGlobalEnvironment = true
    
    @StateObject private var sessionMonitor = SessionMonitor()
    @StateObject private var authenticator = InteractiveAuthenticator()
    
    private var pathResolver = ProjectPathResolver()
    
    enum AuthMode: String, CaseIterable {
        case appSpecificPassword = "应用专属密码"
        case accountPassword = "账号密码"
        
        var description: String {
            switch self {
            case .appSpecificPassword:
                return "使用应用专属密码（推荐）"
            case .accountPassword:
                return "使用账号密码 + 双重验证"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if sessionMonitor.hasValidSession {
                        currentSessionSection
                    } else {
                        authenticationSection
                    }
                    
                    if authenticator.needsTwoFactor {
                        twoFactorSection
                    }
                    
                    if !authenticator.output.isEmpty {
                        outputSection
                    }
                }
                .padding()
            }
            
            Divider()
            footer
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            loadSavedCredentials()
            sessionMonitor.startMonitoring()
        }
        .onDisappear {
            sessionMonitor.stopMonitoring()
        }
        .onReceive(authenticator.$sessionCreated) { created in
            if created {
                showingSuccessAlert = true
                clearForm()
                sessionMonitor.checkSessionStatus()
            }
        }
        .alert("Session 设置成功", isPresented: $showingSuccessAlert) {
            Button("确定") { }
        } message: {
            Text("FASTLANE_SESSION 环境变量已设置，有效期约30天。\n将在第25天开始提醒续期。")
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Session 令牌管理")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("自动设置 FASTLANE_SESSION 环境变量")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            if sessionMonitor.hasValidSession {
                sessionStatusIndicator
            }
        }
        .padding()
    }
    
    private var footer: some View {
        HStack {
            if sessionMonitor.hasValidSession {
                Button("清除 Session") {
                    clearSession()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            Button("关闭") { dismiss() }
                .buttonStyle(.bordered)
                .frame(width: 80)
        }
        .padding()
    }
    
    private var currentSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("当前 Session 状态")
                    .font(.headline)
                Spacer()
                sessionStatusIndicator
            }
            
            if let expiryDate = sessionMonitor.sessionExpiryDate {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("到期时间:")
                        Text(expiryDate, style: .date)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("剩余天数:")
                        Text("\(daysRemaining) 天")
                            .fontWeight(.medium)
                            .foregroundColor(daysRemaining <= 5 ? .red : daysRemaining <= 10 ? .orange : .green)
                    }
                }
                .font(.subheadline)
                
                if daysRemaining <= 5 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Session 即将过期，建议重新生成")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            Button("重新生成 Session") {
                sessionMonitor.clearSession()
                clearForm()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生成新的 Session Token")
                .font(.headline)
            
            Text("请选择认证方式并输入您的 Apple ID 凭证")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 认证方式选择
            VStack(alignment: .leading, spacing: 8) {
                Text("认证方式")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("认证方式", selection: $authMode) {
                    ForEach(AuthMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Apple ID")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("your-apple-id@example.com", text: $appleId)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(authMode == .appSpecificPassword ? "应用专属密码" : "账号密码")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField(authMode == .appSpecificPassword ? "应用专属密码" : "Apple ID 密码", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                if authMode == .appSpecificPassword {
                    Text("请使用应用专属密码，不是Apple ID密码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("输入您的Apple ID账号密码，认证时会要求输入验证码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 环境变量设置选项
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("设置为全局环境变量", isOn: $setGlobalEnvironment)
                    
                    Button(action: {
                        // 显示帮助信息
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("开启后将把Session Token写入shell配置文件(.zshrc, .bash_profile)，使其在新终端窗口中可用")
                }
                
                if setGlobalEnvironment {
                    Text("✓ 将写入shell配置文件，在新终端窗口中可用")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("仅在当前应用进程中设置环境变量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: startAuthentication) {
                    Text(authenticator.isRunning ? "认证中..." : "开始认证")
                }
                .buttonStyle(.borderedProminent)
                .disabled(authenticator.isRunning || appleId.isEmpty || password.isEmpty)
                
                if authenticator.isRunning {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            
            if let error = authenticator.error {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var twoFactorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("双重认证")
                .font(.headline)
            
            if authMode == .accountPassword {
                Text("请输入发送到您信任设备的6位验证码")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("请输入发送到您设备的6位验证码")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TextField("000000", text: $twoFactorCode)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                
                Button("提交") {
                    submitTwoFactorCode()
                }
                .buttonStyle(.borderedProminent)
                .disabled(twoFactorCode.count != 6 || authenticator.isRunning)
            }
            
            Button("取消") {
                authenticator.cancel()
                twoFactorCode = ""
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("执行日志")
                .font(.headline)
            
            ScrollView {
                Text(authenticator.output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
    
    private var sessionStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(sessionMonitor.hasValidSession ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(sessionMonitor.hasValidSession ? "已激活" : "未设置")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private func loadSavedCredentials() {
        if let credential = KeychainStore.loadCredential() {
            appleId = credential.appleId
            // 不自动填充密码，出于安全考虑
        }
    }
    
    private func startAuthentication() {
        guard !authenticator.isRunning else { return }
        guard let fastlaneRoot = pathResolver.fastlaneRoot else {
            authError = "未找到 fastlane 目录"
            return
        }
        
        authError = nil
        let useAppSpecificPassword = (authMode == .appSpecificPassword)
        authenticator.startAuthentication(
            appleId: appleId, 
            password: password, 
            fastlaneRoot: fastlaneRoot,
            useAppSpecificPassword: useAppSpecificPassword,
            setGlobalEnvironment: setGlobalEnvironment
        )
    }
    
    private func submitTwoFactorCode() {
        guard !twoFactorCode.isEmpty else { return }
        authenticator.submitTwoFactorCode(twoFactorCode)
        twoFactorCode = ""
    }
    
    private func processAuthenticationResult(_ output: String) {
        // 这个方法现在由 InteractiveAuthenticator 处理
        // 保留用于兼容性，但实际逻辑已移动到 InteractiveAuthenticator
    }
    
    private func clearSession() {
        sessionMonitor.clearSession()
        unsetenv("FASTLANE_SESSION")
    }
    
    private func clearForm() {
        password = ""
        twoFactorCode = ""
        authError = nil
    }
}

// MARK: - Session Monitor
class SessionMonitor: ObservableObject {
    @Published var hasValidSession = false
    @Published var sessionExpiryDate: Date?
    
    private var notificationTimer: Timer?
    private let userDefaults = UserDefaults.standard
    private var notificationsSupported: Bool {
        // 检查是否在支持通知的环境中
        return Bundle.main.bundleIdentifier != nil && ProcessInfo.processInfo.environment["TERM"] == nil
    }
    
    func startMonitoring() {
        checkSessionStatus()
        
        // 设置定时器，每小时检查一次
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.checkSessionStatus()
            self.checkForExpiryReminder()
        }
        
        // 只在支持的环境中请求通知权限
        if notificationsSupported {
            requestNotificationPermission()
        }
    }
    
    func stopMonitoring() {
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    func saveSession(_ token: String) {
        userDefaults.set(token, forKey: "FASTLANE_SESSION")
        
        // 计算过期时间（30天后）
        let expiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        userDefaults.set(expiryDate, forKey: "SESSION_EXPIRY_DATE")
        userDefaults.set(Date(), forKey: "SESSION_CREATED_DATE")
        
        sessionExpiryDate = expiryDate
        hasValidSession = true
    }
    
    func clearSession() {
        userDefaults.removeObject(forKey: "FASTLANE_SESSION")
        userDefaults.removeObject(forKey: "SESSION_EXPIRY_DATE")
        userDefaults.removeObject(forKey: "SESSION_CREATED_DATE")
        
        hasValidSession = false
        sessionExpiryDate = nil
    }
    
    func checkSessionStatus() {
        // 检查环境变量
        let envSession = ProcessInfo.processInfo.environment["FASTLANE_SESSION"]
        
        // 检查保存的session
        let savedSession = userDefaults.string(forKey: "FASTLANE_SESSION")
        let savedExpiry = userDefaults.object(forKey: "SESSION_EXPIRY_DATE") as? Date
        
        if let session = savedSession ?? envSession,
           !session.isEmpty {
            
            if let expiry = savedExpiry {
                hasValidSession = expiry > Date()
                sessionExpiryDate = expiry
                
                // 如果session过期，清除它
                if !hasValidSession {
                    clearSession()
                }
            } else {
                // 如果没有过期时间记录，假设还有效，但设置一个默认过期时间
                hasValidSession = true
                let defaultExpiry = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                sessionExpiryDate = defaultExpiry
                userDefaults.set(defaultExpiry, forKey: "SESSION_EXPIRY_DATE")
            }
        } else {
            hasValidSession = false
            sessionExpiryDate = nil
        }
    }
    
    private func checkForExpiryReminder() {
        guard let expiryDate = sessionExpiryDate else { return }
        
        let calendar = Calendar.current
        let daysUntilExpiry = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        
        // 在第25天开始每天提醒
        if daysUntilExpiry <= 5 && daysUntilExpiry > 0 && notificationsSupported {
            scheduleExpiryNotification(daysRemaining: daysUntilExpiry)
        }
    }
    
    private func requestNotificationPermission() {
        // 暂时完全禁用通知功能以避免崩溃
        print("通知功能已禁用（开发模式）")
        return
        
        // 以下代码在正式环境中启用
        /*
        // 额外的安全检查
        guard notificationsSupported else {
            print("警告: 在不支持通知的环境中运行，跳过通知权限请求")
            return
        }
        
        // 再次检查bundle环境
        guard Bundle.main.bundleIdentifier != nil else {
            print("警告: 无效的bundle环境，跳过通知权限请求")
            return
        }
        
        // 使用更简单的方法来避免崩溃
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("通知权限请求失败: \(error)")
                }
            }
        }
        */
    }
    
    private func scheduleExpiryNotification(daysRemaining: Int) {
        // 暂时禁用通知调度
        print("通知调度已禁用（开发模式），剩余天数: \(daysRemaining)")
        return
        
        /*
        // 检查是否在正确的应用环境中运行
        guard notificationsSupported else {
            print("警告: 在不支持通知的环境中运行，跳过通知调度")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "FASTLANE_SESSION 即将过期"
        content.body = "您的 session token 将在 \(daysRemaining) 天后过期，请及时更新。"
        content.sound = .default
        
        // 检查今天是否已经发送过通知
        let lastNotificationDate = userDefaults.object(forKey: "LAST_EXPIRY_NOTIFICATION") as? Date
        if let lastDate = lastNotificationDate,
           Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            return // 今天已经发送过通知
        }
        
        let request = UNNotificationRequest(
            identifier: "session-expiry-\(daysRemaining)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                self.userDefaults.set(Date(), forKey: "LAST_EXPIRY_NOTIFICATION")
            }
        }
        */
    }
}

// MARK: - Project Path Resolver
private struct ProjectPathResolver {
    let projectRoot: URL?
    let fastlaneRoot: URL?
    
    init() {
        let fm = FileManager.default
        let candidates = ProjectPathResolver.buildCandidates()
        var foundRoot: URL?
        
        for candidate in candidates {
            if let root = ProjectPathResolver.findPackageRoot(startingAt: candidate, fileManager: fm) {
                foundRoot = root
                break
            }
        }
        
        projectRoot = foundRoot
        
        if let root = foundRoot {
            let fastlanePath = root.appendingPathComponent("fastlane", isDirectory: true)
            if fm.fileExists(atPath: fastlanePath.path) {
                fastlaneRoot = fastlanePath
            } else {
                fastlaneRoot = nil
            }
        } else {
            fastlaneRoot = nil
        }
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
        sourceURL.deleteLastPathComponent()
        sourceURL.deleteLastPathComponent()
        sourceURL.deleteLastPathComponent()
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

#Preview {
    SessionManagerView()
}