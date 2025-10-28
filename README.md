# MacSigner (Xcode-ready)

一个 **macOS 命令行 Signer 客户端**（Swift 5.10, SwiftPM），在 **Xcode 里直接打开 `Package.swift`** 即可运行。
集成 Fastlane：`bundle exec fastlane login/register_udid/resign_ipa` 由 Swift `Process` 驱动。

## � 新功能：GUI Session管理

### ✨ 完整的Session Token自动化管理
- 🎯 **GUI界面化操作**：将复杂的终端命令包装成友好的图形界面
- 🔐 **双重认证支持**：应用专属密码 + 账号密码+2FA 两种模式
- 🌍 **全局环境变量**：自动写入shell配置文件，新终端窗口可用
- ⏰ **智能过期提醒**：30天倒计时，提前5天开始提醒
- ✅ **Session验证**：一键检测token有效性和API访问状态

### 🚀 快速使用Session管理
```bash
# 快速启动Session管理
./quick_session.sh

# 独立验证当前Session状态
./verify_session_token.sh

# 查看详细使用指南
cat FINAL_SESSION_GUIDE.md
```

## �🚀 快速开始

### 一键环境检查
```bash
# 快速检查当前环境状态
./quick_check.sh

# 一键配置完整开发环境（包括 Xcode Tools, Homebrew, Ruby, Fastlane）
./setup_check.sh
```

### 环境要求
- macOS 12.0+
- Xcode Command Line Tools
- Ruby 3.2.8 (通过 rbenv 管理)
- Fastlane 2.228.0+

## 打开与运行（Xcode）
1. 打开 Xcode → `Open` → 选中项目根目录下的 `Package.swift`。
2. 目标选择 `MacSigner`（My Mac）。
3. 在 Scheme 的 `Arguments` 中添加环境变量（至少）:
   - `POOL_BASE_URL=https://pool.example.com`
   - `POOL_API_TOKEN=dev-token`
   - 首次导入 Keychain：`APPLE_ID=your_apple_id@example.com`（可选）

## 终端运行（可选）
```bash
cd fastlane && bundle install
cd ..
swift build
POOL_BASE_URL=https://pool.example.com \
POOL_API_TOKEN=dev-token \
APPLE_ID=your_apple_id@example.com \
swift run MacSigner
```

## 🔑 Apple ID 凭证配置

### 必需信息

1. **Apple ID**: 您的Apple开发者账户邮箱
2. **P12证书**: 用于代码签名的开发者证书
3. **P12密码**: 导出P12文件时设置的密码
4. **Session Token**: (可选) 避免频繁两步验证

### 快速获取步骤

#### 1. Apple ID

- 使用您注册Apple Developer Program的邮箱地址
- 登录 [Apple Developer Console](https://developer.apple.com) 查看

#### 2. P12证书获取

```bash
# 方法1: 钥匙串访问图形界面
1. 打开「钥匙串访问」→ 证书助理 → 从证书颁发机构请求证书
2. 填写邮箱和姓名，保存CSR文件
3. 在Apple Developer Console创建证书，上传CSR
4. 下载.cer文件，双击安装
5. 在钥匙串中导出为.p12格式

# 方法2: 使用现有证书
如果已有开发者证书，直接在钥匙串中导出为.p12格式
```

#### 3. Session Token获取 (推荐)

```bash
# 安装fastlane
gem install fastlane

# 获取session token
fastlane spaceauth -u your-apple-id@example.com
# 按提示完成两步验证，复制生成的session token
```

### 配置方式

1. **GUI配置**: 启动应用后点击「Apple ID」按钮
2. **命令行配置**: 设置环境变量

   ```bash
   export APPLE_ID="your-apple-id@example.com"
   export P12_PATH="/path/to/your/certificate.p12"
   export P12_PASSWORD="your-p12-password"
   export FASTLANE_SESSION="your-session-token"
   ```

> 💡 应用内置详细的「获取指南」，点击Apple ID配置页面的「获取指南」按钮查看完整步骤。

## 注意

- Xcode 打开 SwiftPM 工程与传统 .xcodeproj 等价可运行。
- `resign` 需本机钥匙串有可用的 AdHoc/Distribution 证书与私钥。
- 你的后端需提供 `/api/signer/next|status|result` 等接口。

## 📚 详细文档

- [macOS 开发环境完整配置指南](./MACOS_SETUP_GUIDE.md) - 从零开始的环境设置
- [Ruby 环境配置指南](./RUBY_SETUP.md) - Ruby 和 Fastlane 配置详情

## 🛠️ 环境工具

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `./quick_check.sh` | 快速检查当前环境状态 | 日常开发前的环境验证 |
| `./setup_check.sh` | 一键配置完整开发环境 | 首次设置或环境修复 |
| `./fix_homebrew.sh` | 修复 Homebrew 常见问题 | Homebrew 更新失败时 |

## 📋 常用命令

```bash
# 环境检查
./quick_check.sh                    # 快速检查
./setup_check.sh --help             # 查看帮助

# Swift 项目
swift package resolve               # 解析依赖
swift build                         # 构建项目
swift package clean                 # 清理缓存

# Fastlane
cd fastlane
bundle exec fastlane --version      # 检查版本
bundle exec fastlane lanes          # 查看可用命令
```
