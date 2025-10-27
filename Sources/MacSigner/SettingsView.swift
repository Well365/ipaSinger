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
                Text("设置")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    configurationContent
                }
                .padding()
            }
            
            Divider()
            
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
        .frame(width: 700, height: 600)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // 配置内容视图
    private var configurationContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("服务器配置")
                    .font(.headline)
                formField(title: "服务器地址", text: $serverURL, placeholder: "https://your-server.com")
                formField(title: "API Token", text: $apiToken, placeholder: "your-api-token")
                formField(title: "轮询间隔(秒)", text: $pollInterval, placeholder: "10")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Apple ID 凭证")
                    .font(.headline)
                formField(title: "Apple ID", text: $appleId, placeholder: "your-apple-id@example.com")
                formField(title: "Session Token (可选)", text: $sessionToken, placeholder: "session-token")
                VStack(alignment: .leading, spacing: 8) {
                    Text("P12 证书路径")
                        .font(.subheadline)
                    HStack {
                        NSTextFieldWrapper(text: $p12Path, placeholder: "证书文件路径")
                            .frame(height: 22)
                        Button("选择文件") { selectP12File() }
                            .buttonStyle(.bordered)
                    }
                }
                formField(title: "P12 密码", text: $p12Password, placeholder: "证书密码", isSecure: true)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
        }
    }
    
    private func formField(title: String,
                           text: Binding<String>,
                           placeholder: String,
                           isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            NSTextFieldWrapper(text: text,
                               placeholder: placeholder,
                               isSecure: isSecure)
                .frame(height: 22)
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
        if let url = URL(string: serverURL), !apiToken.isEmpty,
           let interval = Int(pollInterval) {
            let newConfig = Config(
                serverBaseURL: url,
                apiToken: apiToken,
                pollIntervalSec: interval,
                appleAPIKeyID: "",
                appleAPIIssuerID: "",
                appleAPIPrivateKey: ""
            )
            signerManager.updateConfig(newConfig)
        }
        
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
        
        if panel.runModal() == .OK, let url = panel.url {
            p12Path = url.path
        }
    }
}
