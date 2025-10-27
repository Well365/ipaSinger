# Apple Developer API 集成方案

## 概述

为了解决FastLane应用专用密码认证失败的问题，我们实现了直接使用Apple Developer API的解决方案。这个方案避免了FastLane的认证问题，提供更稳定和可靠的自动化签名流程。

## 问题背景

### FastLane方案的问题
- ❌ 应用专用密码认证经常失败
- ❌ 错误信息不清晰
- ❌ 依赖Ruby环境
- ❌ 网络环境敏感
- ❌ 双重认证复杂

### Apple API方案的优势
- ✅ 使用官方API Key认证，更稳定
- ✅ 纯Swift实现，无需Ruby环境
- ✅ 详细的错误信息和日志
- ✅ 支持完整的自动化流程
- ✅ 避免双重认证问题

## 实现架构

### 核心组件

1. **AppleDeveloperAPI.swift**
   - Apple Developer API的Swift客户端
   - JWT Token生成和签名
   - 设备注册、证书管理、Provisioning Profile管理

2. **AppleAPISignExecutor.swift**
   - 使用Apple API的签名执行器
   - 完整的IPA重新签名流程
   - 详细的进度日志

3. **AppleAPIConfigView.swift**
   - Apple API配置界面
   - Key ID、Issuer ID、私钥配置
   - 配置验证和测试

### 配置要求

用户需要在App Store Connect中生成API密钥：

```
Key ID: 10位字符的密钥标识符
Issuer ID: UUID格式的团队标识符
Private Key: .p8格式的私钥文件内容
```

## 使用流程

### 1. 配置Apple API密钥

1. 打开应用程序
2. 点击「Apple API」按钮
3. 按照界面指引配置：
   - 输入Key ID
   - 输入Issuer ID
   - 上传或粘贴.p8私钥内容
4. 点击「测试配置」验证
5. 点击「保存配置」

### 2. 使用Apple API签名

1. 点击「本地签名」
2. 选择要重新签名的IPA文件
3. 输入Bundle ID
4. 输入设备UDID
5. 点击「使用Apple API签名」

### 3. 自动化流程

Apple API签名会自动执行以下步骤：

1. **设备注册**
   - 检查设备是否已注册
   - 如未注册则自动注册新设备

2. **证书获取**
   - 获取可用的开发证书
   - 选择合适的签名证书

3. **Bundle ID验证**
   - 查找指定的Bundle ID
   - 确认Bundle ID存在

4. **Provisioning Profile管理**
   - 查找现有的Profile
   - 如需要则创建新的Profile
   - 下载Profile到本地

5. **IPA重新签名**
   - 解压IPA文件
   - 替换Provisioning Profile
   - 重新签名所有组件
   - 重新打包为新的IPA

## 技术实现细节

### JWT Token生成

```swift
private func generateJWT() throws -> String {
    let header = JWTHeader(alg: "ES256", kid: keyID, typ: "JWT")
    let payload = JWTPayload(
        iss: issuerID,
        exp: Int(Date().addingTimeInterval(20 * 60).timeIntervalSince1970),
        aud: "appstoreconnect-v1"
    )
    
    // 使用P256私钥签名
    let signature = try signMessage(message)
    return "\(message).\(signature)"
}
```

### API请求处理

```swift
private func makeRequest<T: Codable>(
    endpoint: String,
    method: String = "GET",
    body: Data? = nil,
    responseType: T.Type
) async throws -> T {
    var request = URLRequest(url: url)
    request.setValue("Bearer \(try generateJWT())", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(responseType, from: data)
}
```

### 设备注册

```swift
func registerDevice(udid: String, name: String) async throws -> Device {
    let request = DeviceCreateRequest(data: .init(
        type: "devices",
        attributes: .init(name: name, udid: udid, platform: .iOS)
    ))
    
    let response: DeviceResponse = try await makeRequest(
        endpoint: "/v1/devices",
        method: "POST",
        body: try JSONEncoder().encode(request),
        responseType: DeviceResponse.self
    )
    
    return response.data
}
```

## 错误处理

系统提供详细的错误信息：

- **认证错误**: API Key配置问题
- **网络错误**: 连接Apple服务器失败
- **权限错误**: API Key权限不足
- **资源错误**: Bundle ID或证书不存在
- **签名错误**: codesign命令执行失败

## 配置管理

配置信息保存在UserDefaults中：

```swift
UserDefaults.standard.set(keyID, forKey: "AppleAPIKeyID")
UserDefaults.standard.set(issuerID, forKey: "AppleAPIIssuerID")  
UserDefaults.standard.set(privateKey, forKey: "AppleAPIPrivateKey")
```

## 安全考虑

1. 私钥信息仅保存在本地
2. JWT Token有20分钟过期时间
3. 支持环境变量配置，避免硬编码
4. 建议生产环境使用Keychain存储

## 测试和验证

项目包含测试脚本：

```bash
./test_apple_api.sh  # 检查配置状态和使用指南
```

## 下一步计划

1. **Keychain集成**: 将敏感信息存储在Keychain中
2. **批量处理**: 支持批量IPA签名
3. **Enterprise支持**: 支持Enterprise证书和Profile
4. **UI优化**: 改进配置界面和进度显示
5. **日志导出**: 支持详细日志导出和分析

## 总结

Apple Developer API集成方案提供了FastLane的可靠替代方案，解决了认证问题并提供了更好的用户体验。通过纯Swift实现，避免了外部依赖，提高了系统的稳定性和可维护性。

用户现在可以：
- 避免应用专用密码的认证问题
- 享受更稳定的自动化签名流程
- 获得详细的操作日志和错误信息
- 使用现代的API Key认证方式

这个方案为iOS应用的自动化签名和分发提供了强大而可靠的基础。