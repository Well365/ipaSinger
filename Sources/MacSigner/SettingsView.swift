import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var signerManager: SignerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var serverURL = ""
    @State private var apiToken = ""
    @State private var pollInterval = "10"
    
    @State private var appleId = ""
    @State private var sessionToken = ""
    @State private var p12Path = ""
    @State private var p12Password = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("服务器配置")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 服务器配置部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("服务器配置")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("服务器地址")
                                .font(.subheadline)
                            TextField("https://your-server.com", text: $serverURL)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Token")
                                .font(.subheadline)
                            TextField("your-api-token", text: $apiToken)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("轮询间隔(秒)")
                                .font(.subheadline)
                            TextField("10", text: $pollInterval)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // Apple ID 凭证部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Apple ID 凭证")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Apple ID")
                                .font(.subheadline)
                            TextField("your-apple-id@example.com", text: $appleId)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Token (可选)")
                                .font(.subheadline)
                            TextField("session-token", text: $sessionToken)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("P12 证书路径")
                                .font(.subheadline)
                            HStack {
                                TextField("证书文件路径", text: $p12Path)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("选择文件") {
                                    selectP12File()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("P12 密码")
                                .font(.subheadline)
                            SecureField("证书密码", text: $p12Password)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
                .padding()
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(width: 80)
                
                Spacer()
                
                Button("保存") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 80)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        serverURL = signerManager.config.serverBaseURL.absoluteString
        apiToken = signerManager.config.apiToken
        pollInterval = String(signerManager.config.pollIntervalSec)
        
        if let credential = signerManager.currentCredential {
            appleId = credential.appleId
            sessionToken = credential.sessionToken ?? ""
            p12Path = credential.p12Path ?? ""
            p12Password = credential.p12Password ?? ""
        }
    }
    
    private func saveSettings() {
        // 保存服务器配置
        if let url = URL(string: serverURL), !apiToken.isEmpty,
           let interval = Int(pollInterval) {
            let newConfig = Config(
                serverBaseURL: url,
                apiToken: apiToken,
                pollIntervalSec: interval
            )
            signerManager.updateConfig(newConfig)
        }
        
        // 保存凭证
        if !appleId.isEmpty {
            let credential = LoginCredential(
                appleId: appleId,
                sessionToken: sessionToken.isEmpty ? nil : sessionToken,
                p12Path: p12Path.isEmpty ? nil : p12Path,
                p12Password: p12Password.isEmpty ? nil : p12Password
            )
            signerManager.updateCredential(credential)
        }
    }
    
    private func selectP12File() {
        let panel = NSOpenPanel()
        if let p12Type = UTType(filenameExtension: "p12") {
            panel.allowedContentTypes = [p12Type]
        } else {
            panel.allowedContentTypes = [.data]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                p12Path = url.path
            }
        }
    }
}