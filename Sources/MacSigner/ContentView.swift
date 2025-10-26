import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var signerManager: SignerManager
    @State private var showingSettings = false
    @State private var localSignWindowController: LocalSignWindowController?
    @State private var showingEnvironmentSetup = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题栏
            HStack {
                Image(systemName: "signature")
                    .foregroundColor(.blue)
                    .font(.title)
                Text("MacSigner")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("本地签名") {
                    openLocalSignWindow()
                }
                .buttonStyle(.bordered)
                
                Button("环境安装") {
                    showingEnvironmentSetup = true
                }
                .buttonStyle(.bordered)
                
                Button("设置") {
                    showingSettings = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // 状态显示
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(signerManager.isRunning ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text("服务状态: \(signerManager.isRunning ? "运行中" : "已停止")")
                        .font(.headline)
                }
                
                Text("服务器: \(signerManager.config.serverBaseURL.absoluteString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let credential = signerManager.currentCredential {
                    Text("Apple ID: \(credential.appleId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 日志显示
            VStack(alignment: .leading) {
                HStack {
                    Text("运行日志")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("复制日志") {
                        copyLogsToClipboard()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(signerManager.logs.indices, id: \.self) { index in
                            Text(signerManager.logs[index])
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(logColor(for: signerManager.logs[index]))
                                .textSelection(.enabled)
                        }
                    }
                    .padding(8)
                }
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)
                .frame(height: 200)
            }
            
            // 控制按钮
            HStack(spacing: 20) {
                Button(signerManager.isRunning ? "停止服务" : "启动服务") {
                    if signerManager.isRunning {
                        signerManager.stop()
                    } else {
                        signerManager.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(signerManager.config.serverBaseURL.absoluteString.isEmpty)
                
                Button("清空日志") {
                    signerManager.clearLogs()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(signerManager)
        }
        .sheet(isPresented: $showingEnvironmentSetup) {
            EnvironmentSetupView()
        }
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("[ERROR]") {
            return .red
        } else if log.contains("[WARN]") {
            return .orange
        } else if log.contains("[INFO]") {
            return .primary
        } else if log.contains("[SUCCESS]") {
            return .green
        } else if log.contains("[DEBUG]") {
            return .secondary
        }
        return .secondary
    }
    
    private func copyLogsToClipboard() {
        let logsText = signerManager.logs.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logsText, forType: .string)
    }
    
    private func openLocalSignWindow() {
        print("[DEBUG] ========== Opening Local Sign Window ==========")
        
        // 如果窗口控制器已存在，直接显示
        if let controller = localSignWindowController {
            print("[DEBUG] Window controller already exists, showing window")
            controller.show()
            return
        }
        
        // 创建新的窗口控制器
        print("[DEBUG] Creating new window controller")
        let controller = LocalSignWindowController(signerManager: signerManager)
        localSignWindowController = controller
        controller.show()
    }
}