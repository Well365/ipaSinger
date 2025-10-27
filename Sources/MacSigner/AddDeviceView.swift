import SwiftUI

struct AddDeviceView: View {
    @State private var deviceName = ""
    @State private var deviceUDID = ""
    @State private var selectedPlatform: DevicePlatform = .iOS
    @State private var isAdding = false
    @State private var addResult: DeviceOperationResult?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @StateObject private var deviceManager: DeviceManager
    
    init() {
        let config = Config.load()
        let manager = DeviceManager(config: config)
        self._deviceManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "iphone.badge.plus")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("设备管理")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("刷新设备列表") {
                    Task {
                        await deviceManager.refreshDevices()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(deviceManager.isLoading || !deviceManager.isConfigured)
            }
            
            Divider()
            
            // 配置状态检查
            if !deviceManager.isConfigured {
                configurationWarningView
            } else {
                deviceManagementContent
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if deviceManager.isConfigured {
                Task {
                    await deviceManager.refreshDevices()
                }
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 配置警告视图
    
    private var configurationWarningView: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple API 配置不完整")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("需要配置 Apple Developer API 凭证才能使用设备管理功能")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("所需配置项:")
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• API Key ID (10位字符)")
                        .font(.caption)
                    Text("• Issuer ID (UUID格式)")
                        .font(.caption)
                    Text("• Private Key (.p8文件内容)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                
                Button("前往配置") {
                    WindowManager.shared.openAppleAPIConfigWindow()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - 设备管理内容
    
    private var deviceManagementContent: some View {
        VStack(spacing: 20) {
            // 添加设备表单
            VStack(alignment: .leading, spacing: 15) {
                Text("添加新设备")
                    .font(.headline)
                
                // 设备名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("设备名称")
                        .fontWeight(.medium)
                    TextField("例如: Maxwell的iPhone", text: $deviceName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("给设备起一个容易识别的名称")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 设备UDID
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("设备UDID")
                            .fontWeight(.medium)
                        
                        Button("如何获取UDID?") {
                            showUDIDHelp()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    TextField("例如: 00008120-001A10513622201E", text: $deviceUDID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: deviceUDID) { newValue in
                            // 自动格式化UDID
                            let formatted = deviceManager.formatUDID(newValue)
                            if formatted != newValue {
                                deviceUDID = formatted
                            }
                        }
                    
                    HStack {
                        if deviceManager.isValidUDID(deviceUDID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("UDID格式正确")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if !deviceUDID.isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("UDID格式不正确")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("设备的唯一标识符，25位字符")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 设备平台
                VStack(alignment: .leading, spacing: 8) {
                    Text("设备平台")
                        .fontWeight(.medium)
                    
                    Picker("平台", selection: $selectedPlatform) {
                        ForEach(DevicePlatform.allCases, id: \.self) { platform in
                            HStack {
                                Image(systemName: platform.iconName)
                                Text(platform.displayName)
                            }
                            .tag(platform)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 添加按钮
                HStack {
                    Spacer()
                    
                    Button("添加设备") {
                        addDevice()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(deviceName.isEmpty || !deviceManager.isValidUDID(deviceUDID) || isAdding)
                    
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
            
            // 添加结果
            if let result = addResult {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        Text(result.success ? "设备添加成功" : "设备添加失败")
                            .fontWeight(.medium)
                    }
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if result.success, let device = result.device {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("设备信息:")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("名称: \(device.attributes.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("UDID: \(device.attributes.udid)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("平台: \(device.attributes.platform.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
            
            // 已注册设备列表
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("已注册设备")
                        .font(.headline)
                    
                    Spacer()
                    
                    if deviceManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(deviceManager.devices.count) 个设备")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if deviceManager.devices.isEmpty && !deviceManager.isLoading {
                    VStack(spacing: 10) {
                        Image(systemName: "iphone.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("暂无已注册设备")
                            .foregroundColor(.secondary)
                        Text("点击上方添加第一个设备")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(deviceManager.devices) { device in
                                DeviceRowView(device: device)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            // 错误消息显示
            if let errorMessage = deviceManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("清除") {
                        deviceManager.errorMessage = nil
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func showUDIDHelp() {
        alertMessage = UDIDHelper.helpText
        showingAlert = true
    }
    
    private func addDevice() {
        guard !deviceName.isEmpty, deviceManager.isValidUDID(deviceUDID) else { return }
        
        isAdding = true
        addResult = nil
        
        Task {
            let result = await deviceManager.addDevice(
                name: deviceName,
                udid: deviceUDID,
                platform: selectedPlatform
            )
            
            await MainActor.run {
                addResult = result
                
                if result.success {
                    // 清空表单
                    deviceName = ""
                    deviceUDID = ""
                }
                
                isAdding = false
            }
        }
    }
}

// MARK: - 设备行视图
struct DeviceRowView: View {
    let device: Device
    
    var body: some View {
        HStack(spacing: 12) {
            // 设备图标
            Image(systemName: device.attributes.platform.iconName)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            // 设备信息
            VStack(alignment: .leading, spacing: 2) {
                Text(device.attributes.name)
                    .fontWeight(.medium)
                
                Text(device.attributes.udid)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
            // 状态和平台
            VStack(alignment: .trailing, spacing: 2) {
                Text(device.attributes.platform.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Text(device.attributes.status)
                    .font(.caption)
                    .foregroundColor(device.attributes.status == "ENABLED" ? .green : .orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - 设备平台扩展
extension DevicePlatform {
    var displayName: String {
        switch self {
        case .iOS:
            return "iOS"
        case .macOS:
            return "macOS"
        }
    }
    
    var iconName: String {
        switch self {
        case .iOS:
            return "iphone"
        case .macOS:
            return "laptopcomputer"
        }
    }
}

// MARK: - 预览
struct AddDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        AddDeviceView()
            .frame(width: 700, height: 650)
    }
}