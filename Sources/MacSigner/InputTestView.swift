import SwiftUI

struct InputTestView: View {
    @State private var testText1 = ""
    @State private var testText2 = ""
    @State private var testPassword = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("输入功能测试")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试字段1:")
                    TextField("请输入文本", text: $testText1)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            print("TextField 1 submitted: \(testText1)")
                        }
                        .onChange(of: testText1) { newValue in
                            print("TextField 1 changed to: '\(newValue)'")
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试字段2:")
                    TextField("请输入文本", text: $testText2)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            print("TextField 2 submitted: \(testText2)")
                        }
                        .onChange(of: testText2) { newValue in
                            print("TextField 2 changed to: '\(newValue)'")
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("密码字段:")
                    SecureField("请输入密码", text: $testPassword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            print("SecureField submitted: \(testPassword)")
                        }
                        .onChange(of: testPassword) { newValue in
                            print("SecureField changed to: '\(newValue)'")
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前值:")
                    Text("字段1: '\(testText1)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("字段2: '\(testText2)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("密码: '\(testPassword)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            HStack {
                Button("关闭") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("清空所有") {
                    testText1 = ""
                    testText2 = ""
                    testPassword = ""
                }
                .buttonStyle(.bordered)
                
                Button("填充测试") {
                    testText1 = "test1@example.com"
                    testText2 = "dev-token-123"
                    testPassword = "password123"
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
        .onAppear {
            print("InputTestView appeared")
            // 尝试获得窗口焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let window = NSApp.keyWindow {
                    window.makeKey()
                    window.makeKeyAndOrderFront(nil)
                    print("Window made key and ordered front")
                }
            }
        }
    }
}