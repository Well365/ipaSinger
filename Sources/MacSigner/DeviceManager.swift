import Foundation

// MARK: - 设备管理API工具类
class DeviceManager: ObservableObject {
    @Published var devices: [Device] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isConfigured = false
    
    private var api: AppleDeveloperAPI?
    
    init(config: Config) {
        if !config.appleAPIKeyID.isEmpty && 
           !config.appleAPIIssuerID.isEmpty && 
           !config.appleAPIPrivateKey.isEmpty {
            let api = AppleDeveloperAPI(
                keyID: config.appleAPIKeyID,
                issuerID: config.appleAPIIssuerID,
                privateKey: config.appleAPIPrivateKey
            )
            
            // 验证配置
            do {
                try api.validateConfiguration()
                self.api = api
                self.isConfigured = true
                print("[DeviceManager] Apple API configuration validated successfully ✅")
            } catch {
                self.api = nil
                self.isConfigured = false
                self.errorMessage = "Apple API 配置验证失败: \(error.localizedDescription)"
                print("[DeviceManager] Apple API configuration validation failed: \(error)")
            }
        } else {
            self.api = nil
            self.isConfigured = false
            self.errorMessage = "Apple API 配置不完整，请先完成 API 配置"
            print("[DeviceManager] Apple API configuration incomplete")
        }
    }
    
    // MARK: - 设备操作
    
    /// 刷新设备列表
    func refreshDevices() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let api = api else {
            await MainActor.run {
                self.errorMessage = "Apple API 配置不完整，请先完成 API 配置"
                self.isLoading = false
            }
            return
        }
        
        do {
            let deviceList = try await api.listDevices()
            
            await MainActor.run {
                self.devices = deviceList.sorted { device1, device2 in
                    // 按状态排序（启用的设备在前）
                    if device1.attributes.status != device2.attributes.status {
                        return device1.attributes.status == "ENABLED"
                    }
                    // 然后按名称排序
                    return device1.attributes.name < device2.attributes.name
                }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "获取设备列表失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// 添加新设备
    func addDevice(name: String, udid: String, platform: DevicePlatform) async -> DeviceOperationResult {
        // 检查API配置
        guard let api = api else {
            return DeviceOperationResult(success: false, message: "Apple API 配置不完整，请先完成 API 配置")
        }
        
        // 输入验证
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return DeviceOperationResult(success: false, message: "设备名称不能为空")
        }
        
        guard isValidUDID(udid) else {
            return DeviceOperationResult(success: false, message: "UDID格式不正确")
        }
        
        do {
            // 检查设备是否已存在
            if let existingDevice = try await api.findDevice(udid: udid) {
                return DeviceOperationResult(
                    success: false,
                    message: "设备已存在: \(existingDevice.attributes.name)",
                    device: existingDevice
                )
            }
            
            // 添加新设备
            let device = try await api.registerDevice(
                udid: udid,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                platform: platform
            )
            
            // 刷新设备列表
            await refreshDevices()
            
            return DeviceOperationResult(
                success: true,
                message: "设备添加成功",
                device: device
            )
            
        } catch {
            return DeviceOperationResult(
                success: false,
                message: "添加设备失败: \(error.localizedDescription)"
            )
        }
    }
    
    /// 查找设备
    func findDevice(udid: String) async -> Device? {
        guard let api = api else {
            await MainActor.run {
                self.errorMessage = "Apple API 配置不完整，请先完成 API 配置"
            }
            return nil
        }
        
        do {
            return try await api.findDevice(udid: udid)
        } catch {
            await MainActor.run {
                self.errorMessage = "查找设备失败: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    /// 检查设备是否已注册
    func isDeviceRegistered(udid: String) async -> Bool {
        let device = await findDevice(udid: udid)
        return device != nil
    }
    
    // MARK: - 验证方法
    
    /// 验证UDID格式
    func isValidUDID(_ udid: String) -> Bool {
        // iOS设备UDID格式: 25位字符，通常是 8-4-4-4-12 的格式
        let pattern = "^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: udid.utf16.count)
        return regex?.firstMatch(in: udid, options: [], range: range) != nil
    }
    
    /// 格式化UDID
    func formatUDID(_ input: String) -> String {
        // 移除所有非字母数字字符
        let alphanumeric = input.uppercased().filter { $0.isLetter || $0.isNumber }
        
        // 如果长度不是25位，返回原始输入
        guard alphanumeric.count == 25 else {
            return input.uppercased()
        }
        
        // 格式化为 8-4-4-4-12 格式
        let formatted = String(alphanumeric.prefix(8)) + "-" +
                       String(alphanumeric.dropFirst(8).prefix(4)) + "-" +
                       String(alphanumeric.dropFirst(12).prefix(4)) + "-" +
                       String(alphanumeric.dropFirst(16).prefix(4)) + "-" +
                       String(alphanumeric.dropFirst(20))
        
        return formatted
    }
    
    // MARK: - 统计信息
    
    /// 获取设备统计信息
    var deviceStats: DeviceStats {
        let total = devices.count
        let enabled = devices.filter { $0.attributes.status == "ENABLED" }.count
        let iOS = devices.filter { $0.attributes.platform == .iOS }.count
        let macOS = devices.filter { $0.attributes.platform == .macOS }.count
        
        return DeviceStats(
            total: total,
            enabled: enabled,
            disabled: total - enabled,
            iOS: iOS,
            macOS: macOS
        )
    }
}

// MARK: - 数据模型

struct DeviceOperationResult {
    let success: Bool
    let message: String
    let device: Device?
    
    init(success: Bool, message: String, device: Device? = nil) {
        self.success = success
        self.message = message
        self.device = device
    }
}

struct DeviceStats {
    let total: Int
    let enabled: Int
    let disabled: Int
    let iOS: Int
    let macOS: Int
}

// MARK: - 错误定义

enum DeviceManagerError: LocalizedError {
    case missingConfiguration
    case invalidUDID
    case deviceNotFound
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Apple API配置不完整，请先配置API密钥"
        case .invalidUDID:
            return "设备UDID格式无效"
        case .deviceNotFound:
            return "未找到指定的设备"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}

// MARK: - UDID工具类

class UDIDHelper {
    
    /// 生成UDID帮助文档
    static let helpText = """
    获取iOS设备UDID的方法：
    
    方法1 - 设备设置:
    设置 → 通用 → 关于本机 → 向下滑动找到"设备标识符"
    
    方法2 - iTunes/Finder:
    1. 将设备连接到电脑
    2. 打开iTunes或Finder
    3. 选择设备，查看设备信息
    4. 点击序列号位置，会显示UDID
    
    方法3 - Xcode:
    1. 打开Xcode
    2. Window → Devices and Simulators
    3. 选择设备，UDID显示在设备信息中
    
    方法4 - 第三方工具:
    使用3uTools、iMazing等工具查看设备信息
    
    UDID格式: 25位字符，例如 00008120-001A10513622201E
    """
    
    /// UDID示例
    static let examples = [
        "00008120-001A10513622201E",
        "00008030-001E24E03AA8002E",
        "00008101-000255021E08001E",
        "00008027-001A59E13C6B002E"
    ]
    
    /// 验证UDID格式
    static func validate(_ udid: String) -> ValidationResult {
        let trimmed = udid.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return ValidationResult(isValid: false, message: "UDID不能为空")
        }
        
        if trimmed.count != 25 {
            return ValidationResult(isValid: false, message: "UDID应为25位字符")
        }
        
        let pattern = "^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        
        if regex?.firstMatch(in: trimmed, options: [], range: range) != nil {
            return ValidationResult(isValid: true, message: "UDID格式正确")
        } else {
            return ValidationResult(isValid: false, message: "UDID格式不正确，应为 XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX")
        }
    }
}

struct ValidationResult {
    let isValid: Bool
    let message: String
}