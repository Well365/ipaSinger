# MacSigner - macOS IPA 签名服务

MacSigner 是一个在 macOS 上运行的自动化 iOS 应用签名服务，支持图形界面和自动化任务处理。

## 功能特性

- ✅ **图形界面**：基于 SwiftUI 的现代化 macOS 应用
- ✅ **自动任务轮询**：从矿池中控自动获取签名任务
- ✅ **UDID 注册**：自动注册设备到 Apple 开发者账号
- ✅ **IPA 重签名**：支持 AdHoc 和 In-House 分发
- ✅ **Provisioning Profile 管理**：自动生成和下载配置文件
- ✅ **文件上传**：自动上传签名后的 IPA 到 CDN
- ✅ **凭证管理**：安全存储 Apple ID 凭证到 macOS Keychain

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 14.0 或更高版本
- Ruby 2.7+ (macOS 自带)
- Bundler (用于管理 Fastlane)

## 安装步骤

### 1. 克隆项目

```bash
cd ~/Downloads
# 项目已经在 MacSigner 目录中
cd MacSigner
```

### 2. 安装 Fastlane

```bash
cd fastlane
bundle install
cd ..
```

### 3. 配置 Apple 开发者账号

#### 方式一：使用 Apple ID + 密码（推荐用于开发测试）

```bash
export APPLE_ID="your-apple-id@example.com"
export APPLE_PASSWORD="your-app-specific-password"
```

#### 方式二：使用 App Store Connect API Key（推荐用于生产环境）

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入「用户和访问」→「密钥」
3. 创建新的 API 密钥（需要「管理」权限）
4. 下载 `.p8` 文件

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_KEY_PATH="/path/to/AuthKey_XXXXXX.p8"
```

### 4. 配置环境变量

创建 `.env` 文件（可选，也可以在应用界面中配置）：

```bash
# 矿池中控服务器地址
export POOL_BASE_URL="https://your-pool-server.com"

# API 认证 Token
export POOL_API_TOKEN="your-api-token-here"

# 轮询间隔（秒）
export POLL_INTERVAL="10"

# Apple 开发者账号（首次运行时设置）
export APPLE_ID="your-apple-id@example.com"

# 可选：会话 Token（如果使用 2FA）
export SESSION_TOKEN="your-fastlane-session-token"

# 可选：P12 证书路径和密码
export P12_PATH="/path/to/certificate.p12"
export P12_PASSWORD="certificate-password"
```

## 运行应用

### 方式一：使用 Xcode（推荐开发调试）

1. 打开项目：
   ```bash
   open Package.swift
   ```

2. 在 Xcode 中选择 `MacSigner` scheme

3. 点击运行按钮（⌘R）或菜单 Product → Run

### 方式二：命令行编译运行

```bash
# 编译项目
swift build -c release

# 运行应用
.build/release/MacSigner
```

### 方式三：生成可分发的 .app

```bash
# 编译发布版本
swift build -c release

# 创建 .app 包
mkdir -p MacSigner.app/Contents/MacOS
cp .build/release/MacSigner MacSigner.app/Contents/MacOS/
```

## 使用说明

### 首次启动

1. **设置凭证**：
   - 如果是首次运行，应用会检查环境变量中的 `APPLE_ID`
   - 凭证会自动保存到 macOS Keychain
   - 也可以通过界面的「设置」菜单配置

2. **验证登录**：
   - 应用启动时会自动验证 Apple 开发者账号
   - 确保凭证有效

3. **配置服务器**：
   - 在设置中配置矿池中控服务器地址
   - 设置 API Token
   - 调整轮询间隔

### 主界面说明

应用界面包含以下部分：

- **状态显示**：显示当前服务运行状态
- **任务列表**：显示正在处理和已完成的任务
- **日志输出**：实时显示详细的操作日志
- **控制按钮**：启动/停止服务

### 工作流程

1. **获取任务**：
   - 应用定期从矿池中控获取待处理的签名任务
   - 任务包含：IPA ID、UDID、Bundle ID 等信息

2. **下载 IPA**：
   - 从服务器下载原始 IPA 文件到本地

3. **注册设备**：
   - 将用户设备的 UDID 注册到 Apple 开发者账号
   - 自动生成包含该设备的 Provisioning Profile

4. **重签名 IPA**：
   - 使用 Fastlane 对 IPA 进行重签名
   - 应用新的 Provisioning Profile
   - 可选：修改 Bundle ID、版本号等

5. **上传结果**：
   - 将签名后的 IPA 上传到 CDN
   - 向服务器报告任务完成状态
   - 返回下载链接

## 配置文件说明

### Package.swift

Swift Package Manager 配置文件，定义了项目依赖和构建设置。

### fastlane/Fastfile

Fastlane 自动化脚本，包含以下 Lane：

- `login`: 验证 Apple 开发者账号登录
- `register_udid`: 注册设备 UDID
- `resign_ipa`: 重签名 IPA 文件

### fastlane/Gemfile

Ruby 依赖配置，指定 Fastlane 版本。

## 故障排除

### 问题 1：编译错误 "main attribute cannot be used"

**解决方案**：确保只有一个 `@main` 入口点。如果有 `main.swift.bak` 备份文件，可以删除它。

```bash
rm Sources/MacSigner/main.swift.bak
```

### 问题 2：Fastlane 命令找不到

**解决方案**：确保已安装 Bundler 和 Fastlane

```bash
gem install bundler
cd fastlane
bundle install
```

### 问题 3：Apple ID 登录失败

**解决方案**：
- 如果启用了双因素认证，使用 App Store Connect API Key
- 或者生成应用专用密码：https://appleid.apple.com

### 问题 4：证书或配置文件问题

**解决方案**：
- 确保开发者账号有效
- 检查证书是否过期
- 使用 Xcode 手动创建一次 Provisioning Profile

### 问题 5：上传 IPA 失败

**解决方案**：
- 检查网络连接
- 确认 CDN 配置正确
- 查看日志中的详细错误信息

## API 接口说明

MacSigner 需要与矿池中控服务器交互，服务器需要提供以下接口：

### 1. 获取任务

```
GET /api/signer/next
Authorization: Bearer {API_TOKEN}

Response 200:
{
  "taskId": "task-uuid-123",
  "ipaId": "ipa-uuid-456",
  "udid": "00008030-001234567890001E",
  "bundleId": "com.example.app",
  "minOS": "13.0",
  "resignOptions": {
    "provisioningProfileId": "profile-id",
    "teamId": "TEAM123456",
    "newBundleId": "com.example.app.resigned"
  }
}

Response 204: 无任务
```

### 2. 报告状态

```
POST /api/signer/{taskId}/status
Authorization: Bearer {API_TOKEN}
Content-Type: application/json

{
  "status": "running|success|failed",
  "message": "可选的状态消息"
}
```

### 3. 上传结果

```
POST /api/signer/{taskId}/result
Authorization: Bearer {API_TOKEN}
Content-Type: application/json

{
  "downloadURL": "https://cdn.example.com/signed/app-resigned.ipa"
}
```

### 4. 下载 IPA

```
GET /api/ipa/{ipaId}/download
Authorization: Bearer {API_TOKEN}

Response: IPA 文件二进制流
```

### 5. 上传签名后的 IPA

```
POST /api/ipa/upload
Authorization: Bearer {API_TOKEN}
Content-Type: multipart/form-data

Form Data:
  - file: IPA 文件
  - taskId: 任务 ID

Response:
{
  "url": "https://cdn.example.com/signed/app.ipa"
}
```

## 项目结构

```
MacSigner/
├── Package.swift                    # Swift Package 配置
├── README.md                        # 本文档
├── .gitignore                       # Git 忽略文件
├── fastlane/
│   ├── Fastfile                     # Fastlane 自动化脚本
│   └── Gemfile                      # Ruby 依赖
└── Sources/
    └── MacSigner/
        ├── main.swift               # 应用入口
        ├── MacSignerApp.swift       # SwiftUI App 定义（已存在）
        ├── ContentView.swift        # 主界面视图
        ├── SettingsView.swift       # 设置界面
        ├── Config.swift             # 配置管理
        ├── Models.swift             # 数据模型
        ├── APIClient.swift          # API 客户端
        ├── SignerManager.swift      # 签名任务管理器
        ├── SignExecutor.swift       # 签名执行器协议
        ├── SignExecutorFastlane.swift # Fastlane 实现
        ├── ProcessRunner.swift      # 进程执行工具
        ├── KeychainStore.swift      # Keychain 存储
        └── Logger.swift             # 日志工具
```

## 安全建议

1. **不要将凭证提交到代码仓库**
   - 使用环境变量或 Keychain 存储敏感信息
   - `.gitignore` 已配置忽略凭证文件

2. **使用 App Store Connect API Key**
   - 比 Apple ID + 密码更安全
   - 可以设置更细粒度的权限
   - 不受双因素认证影响

3. **定期更新证书**
   - 监控证书过期时间
   - 及时续期或更新

4. **限制 API Token 权限**
   - 为不同的 Signer 使用不同的 Token
   - 定期轮换 Token

## 开发和贡献

### 编译调试

```bash
# Debug 模式
swift build

# Release 模式
swift build -c release

# 运行测试（如果有）
swift test
```

### 代码风格

- 使用 Swift 标准命名规范
- 优先使用 `async/await` 处理异步操作
- 添加适当的注释和文档

## 许可证

[添加你的许可证信息]

## 联系方式

[添加你的联系方式]

---

**注意**：本应用需要有效的 Apple 开发者账号才能正常工作。确保你的账号有足够的设备配额和证书额度。
