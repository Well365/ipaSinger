import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct AppleCredentialView: View {
    @EnvironmentObject private var signerManager: SignerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var appleId = ""
    @State private var sessionToken = ""
    @State private var p12Path = ""
    @State private var p12Password = ""
    @State private var showingHelp = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    credentialSection
                }
                .padding()
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 420)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear { 
            loadValues()
            // 确保窗口可以接收键盘输入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.keyWindow?.makeKeyAndOrderFront(nil)
            }
        }
        .sheet(isPresented: $showingHelp) {
            CredentialHelpView()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Apple 帐号设置")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button("获取指南") {
                showingHelp = true
            }
            .buttonStyle(.bordered)
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
    
    private var credentialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("开发者凭证")
                .font(.headline)
            formField(title: "Apple ID", text: $appleId, placeholder: "your-apple-id@example.com")
            formField(title: "Session Token (可选)", text: $sessionToken, placeholder: "session-token")
            VStack(alignment: .leading, spacing: 8) {
                Text("P12 证书路径")
                    .font(.subheadline)
                HStack {
                    TextField("证书文件路径", text: $p12Path)
                        .textFieldStyle(.roundedBorder)
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
    
    private func formField(title: String,
                           text: Binding<String>,
                           placeholder: String,
                           isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .onAppear {
            print("[DEBUG] FormField appeared: \(title) = '\(text.wrappedValue)'")
        }
    }
    
    private func loadValues() {
        guard let credential = signerManager.currentCredential else { return }
        appleId = credential.appleId
        sessionToken = credential.sessionToken ?? ""
        p12Path = credential.p12Path ?? ""
        p12Password = credential.p12Password ?? ""
    }
    
    private func saveValues() {
        guard !appleId.isEmpty else { return }
        let credential = LoginCredential(appleId: appleId,
                                         sessionToken: sessionToken.isEmpty ? nil : sessionToken,
                                         p12Path: p12Path.isEmpty ? nil : p12Path,
                                         p12Password: p12Password.isEmpty ? nil : p12Password)
        signerManager.updateCredential(credential)
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
