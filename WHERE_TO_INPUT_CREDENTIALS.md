# 🔑 Apple Developer API 凭证配置指南

## 📍 **在哪里输入凭证？**

### 方法 1: 通过 MacSigner 图形界面（推荐）

#### 步骤详解：

1. **启动 MacSigner 应用**
   ```bash
   cd /Users/maxwell/Documents/idears/ipaSingerMac
   swift run MacSigner
   ```

2. **进入设备管理**
   - 在主界面点击 **"设备管理"** 按钮
   - 或者使用快捷键

3. **进入 Apple API 配置**
   - 在设备管理界面，点击 **"前往配置"** 按钮
   - 这会打开 Apple API 配置窗口

4. **输入您的真实凭证**
   ```
   Key ID: [您的10位Key ID]
   例如: ABC123DEFG
   
   Issuer ID: [您的UUID格式Issuer ID] 
   例如: 12345678-1234-1234-1234-123456789012
   
   Private Key: [完整的P8文件内容]
   例如:
   -----BEGIN PRIVATE KEY-----
   MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg...
   -----END PRIVATE KEY-----
   ```

5. **测试连接**
   - 点击 **"测试连接"** 按钮验证配置
   - 看到 ✅ 成功提示后保存配置

---

### 方法 2: 通过环境变量（临时测试）

如果应用启动有问题，可以通过环境变量设置：

```bash
# 设置环境变量
export APPLE_API_KEY_ID="您的Key ID"
export APPLE_API_ISSUER_ID="您的Issuer ID"
export APPLE_API_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
您的完整私钥内容
-----END PRIVATE KEY-----"

# 然后运行应用
swift run MacSigner
```

---

### 方法 3: 直接编辑配置文件

您也可以直接在代码中设置（仅用于测试）：

编辑 `Sources/MacSigner/Config.swift` 文件：

```swift
// 在 Config 结构体中添加默认值
struct Config: ObservableObject {
    // Apple API 配置
    @Published var appleAPIKeyID: String = "您的Key ID"
    @Published var appleAPIIssuerID: String = "您的Issuer ID"  
    @Published var appleAPIPrivateKey: String = """
    -----BEGIN PRIVATE KEY-----
    您的完整私钥内容
    -----END PRIVATE KEY-----
    """
    // ... 其他配置
}
```

---

## 🔑 **如何获取正确的凭证？**

### 1. 登录 App Store Connect
访问: https://appstoreconnect.apple.com/

### 2. 创建 API 密钥
1. 进入 **"用户和访问权限"** → **"密钥"**
2. 点击 **"生成 API 密钥"**
3. 设置名称和权限（至少需要 Developer 权限）
4. **立即下载 .p8 文件**（只能下载一次！）

### 3. 记录关键信息
- **Key ID**: 密钥页面显示的10位字符
- **Issuer ID**: 密钥页面顶部的 UUID
- **Private Key**: .p8 文件的完整内容

---

## 🧪 **验证配置是否正确**

配置完成后，运行测试：

```bash
# 方法1: 通过应用界面测试
# 在 Apple API 配置界面点击"测试连接"

# 方法2: 通过命令行测试
cd /Users/maxwell/Documents/idears/ipaSingerMac
swift jwt_debug.swift
```

**成功的标志：**
- ✅ JWT 生成成功
- ✅ API 连接返回 200 状态码
- ✅ 能够获取设备列表

**失败的标志：**
- ❌ 401 未授权错误
- ❌ 私钥格式错误
- ❌ Key ID 或 Issuer ID 不匹配

---

## 🚨 **常见问题解决**

### Q: 应用启动失败怎么办？
A: 使用环境变量方式，或直接编辑配置文件

### Q: 仍然收到 401 错误？
A: 检查：
- Key ID 是否正确（10个字符）
- Issuer ID 是否正确（UUID格式）
- 私钥是否完整（包含 BEGIN/END 行）
- API 密钥是否有足够权限

### Q: 私钥格式不对？
A: 确保包含完整的 PEM 格式：
```
-----BEGIN PRIVATE KEY-----
[Base64编码内容，不要有额外空格或换行]
-----END PRIVATE KEY-----
```

---

## 🎯 **快速开始**

最简单的方式：

1. **获取 Apple API 密钥** （从 App Store Connect）
2. **启动 MacSigner** （`swift run MacSigner`）
3. **点击"设备管理"** → **"前往配置"**
4. **填入真实凭证** → **"测试连接"** → **保存**
5. **开始使用设备管理功能！** 🎉

您的技术实现已经完美，只需要真实的 API 凭证即可立即使用！