import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var signerManager: SignerManager
    @State private var showingSettings = false
    
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
                Text("运行日志")
                    .font(.headline)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(signerManager.logs.indices, id: \.self) { index in
                            Text(signerManager.logs[index])
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(logColor(for: signerManager.logs[index]))
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
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("[ERROR]") {
            return .red
        } else if log.contains("[WARN]") {
            return .orange
        } else if log.contains("[INFO]") {
            return .primary
        }
        return .secondary
    }
}