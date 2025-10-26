import SwiftUI

struct ServerConfigView: View {
    @EnvironmentObject private var signerManager: SignerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var serverURL = ""
    @State private var apiToken = ""
    @State private var pollInterval = "10"
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    configurationSection
                }
                .padding()
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 420)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear { loadValues() }
    }
    
    private var header: some View {
        HStack {
            Text("服务器配置")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
    }
    
    private var footer: some View {
        HStack {
            Button("取消") { dismiss() }
                .buttonStyle(.bordered)
                .frame(width: 80)
            Spacer()
            Button("保存") {
                saveValues()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(width: 80)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("服务端参数")
                .font(.headline)
            formField(title: "服务器地址", text: $serverURL, placeholder: "https://your-server.com")
            formField(title: "API Token", text: $apiToken, placeholder: "your-api-token")
            formField(title: "轮询间隔(秒)", text: $pollInterval, placeholder: "10")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
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
    
    private func loadValues() {
        serverURL = signerManager.config.serverBaseURL.absoluteString
        apiToken = signerManager.config.apiToken
        pollInterval = String(signerManager.config.pollIntervalSec)
    }
    
    private func saveValues() {
        guard let url = URL(string: serverURL), !apiToken.isEmpty, let interval = Int(pollInterval) else { return }
        let newConfig = Config(serverBaseURL: url,
                               apiToken: apiToken,
                               pollIntervalSec: interval)
        signerManager.updateConfig(newConfig)
    }
}
