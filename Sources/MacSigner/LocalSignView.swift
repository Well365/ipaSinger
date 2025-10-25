import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct LocalSignView: View {
    @EnvironmentObject private var signerManager: SignerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedIPAPath = ""
    @State private var bundleId = ""
    @State private var developerId = ""
    @State private var uuid = ""
    @State private var isSigning = false
    @State private var signProgress = ""
    @State private var signResult: SignResult?
    
    // 上传相关状态
    @State private var uploadURL = ""
    @State private var enableUpload = false
    @State private var isUploading = false
    @State private var uploadProgress = ""
    @State private var uploadResult: UploadResult?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("本地IPA签名")
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
                    // IPA文件选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IPA文件")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("选择IPA文件", text: $selectedIPAPath)
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)
                            
                            Button("选择文件") {
                                selectIPAFile()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // 签名参数
                    VStack(alignment: .leading, spacing: 12) {
                        Text("签名参数")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bundle ID")
                                .font(.subheadline)
                            TextField("com.example.app", text: $bundleId)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Developer ID")
                                .font(.subheadline)
                            TextField("Apple Development: Your Name (XXXXXXXXXX)", text: $developerId)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Device UUID")
                                .font(.subheadline)
                            TextField("设备UUID", text: $uuid)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // 上传配置
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("上传配置")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("启用上传", isOn: $enableUpload)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        
                        if enableUpload {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("上传URL")
                                    .font(.subheadline)
                                TextField("https://your-server.com/upload", text: $uploadURL)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // 进度显示
                    if isSigning {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("签名进度")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(signProgress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ProgressView()
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 上传进度显示
                    if isUploading {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("上传进度")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(uploadProgress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ProgressView()
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 上传结果显示
                    if let uploadResult = uploadResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("上传结果")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: uploadResult.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(uploadResult.success ? .green : .red)
                                
                                Text(uploadResult.success ? "上传成功" : "上传失败")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if let message = uploadResult.message {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if uploadResult.success, let downloadURL = uploadResult.downloadURL {
                                HStack {
                                    Text("下载链接:")
                                        .font(.caption)
                                    Text(downloadURL)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Button("复制") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(downloadURL, forType: .string)
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(uploadResult.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 结果显示
                    if let result = signResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("签名结果")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.success ? .green : .red)
                                
                                Text(result.success ? "签名成功" : "签名失败")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if let message = result.message {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if result.success, let outputPath = result.outputPath {
                                HStack {
                                    Text("输出文件:")
                                        .font(.caption)
                                    Text(outputPath)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Button("打开") {
                                        NSWorkspace.shared.selectFile(outputPath, inFileViewerRootedAtPath: "")
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
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
                
                Button("开始签名") {
                    startSigning()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 100)
                .disabled(selectedIPAPath.isEmpty || bundleId.isEmpty || developerId.isEmpty || uuid.isEmpty || isSigning)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
    }
    
    private func selectIPAFile() {
        let panel = NSOpenPanel()
        if let ipaType = UTType(filenameExtension: "ipa") {
            panel.allowedContentTypes = [ipaType]
        } else {
            panel.allowedContentTypes = [.data]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "选择IPA文件"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedIPAPath = url.path
            }
        }
    }
    
    private func startSigning() {
        guard !selectedIPAPath.isEmpty,
              !bundleId.isEmpty,
              !developerId.isEmpty,
              !uuid.isEmpty else {
            return
        }
        
        if enableUpload && uploadURL.isEmpty {
            return
        }
        
        isSigning = true
        signProgress = "准备签名..."
        signResult = nil
        uploadResult = nil
        
        Task {
            do {
                let result = try await signerManager.signLocalIPA(
                    ipaPath: selectedIPAPath,
                    bundleId: bundleId,
                    developerId: developerId,
                    uuid: uuid
                )
                
                await MainActor.run {
                    self.signResult = result
                    self.isSigning = false
                }
                
                // 如果签名成功且启用了上传，则上传文件
                if result.success, enableUpload, !uploadURL.isEmpty {
                    await MainActor.run {
                        self.isUploading = true
                        self.uploadProgress = "准备上传..."
                    }
                    
                    do {
                        let uploadResult = try await signerManager.uploadFile(
                            filePath: result.outputPath!,
                            uploadURL: uploadURL
                        )
                        
                        await MainActor.run {
                            self.uploadResult = uploadResult
                            self.isUploading = false
                        }
                    } catch {
                        await MainActor.run {
                            self.uploadResult = UploadResult(success: false, message: error.localizedDescription, downloadURL: nil)
                            self.isUploading = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.signResult = SignResult(success: false, message: error.localizedDescription, outputPath: nil)
                    self.isSigning = false
                }
            }
        }
    }
}

struct SignResult {
    let success: Bool
    let message: String?
    let outputPath: String?
}

struct UploadResult {
    let success: Bool
    let message: String?
    let downloadURL: String?
}
