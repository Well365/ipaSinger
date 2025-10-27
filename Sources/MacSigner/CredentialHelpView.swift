import SwiftUI

struct CredentialHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("Apple ID 凭证获取指南")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    credentialGuideContent
                }
                .padding()
            }
        }
        .frame(width: 800, height: 700)
    }
    
    private var credentialGuideContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Apple ID 部分
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("Apple ID (必需)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text("使用您的Apple开发者账户邮箱地址")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("获取方式：")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 登录 Apple Developer Console 查看账户信息")
                        Text("• 使用注册 Apple Developer Program 的邮箱")
                    }
                    .font(.caption)
                }
                
                Text("示例: developer@example.com")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // P12证书部分
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("P12 证书文件 (必需)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text("用于代码签名的开发者证书")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        Text("步骤 1: 生成证书签名请求 (CSR)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. 打开「钥匙串访问」应用")
                            Text("2. 菜单：钥匙串访问 → 证书助理 → 从证书颁发机构请求证书")
                            Text("3. 填写您的邮箱和姓名，选择「存储到磁盘」")
                            Text("4. 保存 CSR 文件")
                        }
                        .font(.caption)
                        .padding(.leading, 16)
                    }
                    
                    Group {
                        Text("步骤 2: 在 Apple Developer 创建证书")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. 登录 Apple Developer Console → Certificates")
                            Text("2. 点击 \"+\" 创建新证书")
                            Text("3. 选择类型：iOS App Development 或 iOS Distribution")
                            Text("4. 上传 CSR 文件，下载生成的 .cer 证书")
                        }
                        .font(.caption)
                        .padding(.leading, 16)
                    }
                    
                    Group {
                        Text("步骤 3: 导出 P12 文件")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. 双击 .cer 文件安装到钥匙串")
                            Text("2. 在钥匙串中找到证书，右键选择「导出」")
                            Text("3. 格式选择「个人信息交换(.p12)」")
                            Text("4. 设置密码并导出")
                        }
                        .font(.caption)
                        .padding(.leading, 16)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // P12密码部分
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("P12 证书密码 (必需)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text("导出P12文件时设置的密码")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("注意事项：")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 请记住您在导出P12时设置的密码")
                        Text("• 建议使用强密码保护证书安全")
                        Text("• 如果忘记密码，需要重新导出P12文件")
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // Session Token部分
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "4.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    Text("Session Token (可选，推荐)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text("避免频繁的两步验证，提高签名效率")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        Text("方法 1: 使用 Fastlane (推荐)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("终端命令：")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("# 安装 fastlane")
                                Text("gem install fastlane")
                                Text("")
                                Text("# 获取 session token")
                                Text("fastlane spaceauth -u your-apple-id@example.com")
                            }
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(4)
                        }
                    }
                    
                    Group {
                        Text("方法 2: 使用 altool")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("终端命令：")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("xcrun altool --list-apps -u \"your-apple-id@example.com\" -p \"app-specific-password\"")
                                .font(.system(.caption, design: .monospaced))
                                .padding(8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("注意：获取 Session Token 需要：")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("• 启用两步验证的 Apple ID")
                        Text("• 生成应用专用密码 (App-Specific Password)")
                        Text("• 在 appleid.apple.com 中生成")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // 配置完成提示
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("配置完成")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("获取所有信息后，在「Apple ID」配置页面填写：")
                        .font(.subheadline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("✓ Apple ID: 您的开发者邮箱")
                        Text("✓ P12 证书路径: 选择导出的 .p12 文件")
                        Text("✓ P12 密码: 导出时设置的密码")
                        Text("✓ Session Token: (可选) 通过命令行获取")
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            // 有用链接
            VStack(alignment: .leading, spacing: 12) {
                Text("有用链接")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Link("Apple Developer Console", destination: URL(string: "https://developer.apple.com/account/resources/certificates/list")!)
                        .font(.caption)
                    
                    Link("App Store Connect", destination: URL(string: "https://appstoreconnect.apple.com")!)
                        .font(.caption)
                    
                    Link("Apple ID 管理", destination: URL(string: "https://appleid.apple.com")!)
                        .font(.caption)
                    
                    Link("Fastlane 文档", destination: URL(string: "https://docs.fastlane.tools")!)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            .cornerRadius(8)
        }
    }
}