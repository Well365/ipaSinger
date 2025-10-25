# MacSigner (Xcode-ready)

一个 **macOS 命令行 Signer 客户端**（Swift 5.10, SwiftPM），在 **Xcode 里直接打开 `Package.swift`** 即可运行。
集成 Fastlane：`bundle exec fastlane login/register_udid/resign_ipa` 由 Swift `Process` 驱动。

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

## Fastlane 鉴权（择一）
- **推荐：ASC API Key**
  ```bash
  export ASC_KEY_ID=ABC1234567
  export ASC_ISSUER_ID=11111111-2222-3333-4444-555555555555
  export ASC_KEY_PATH=/abs/path/AuthKey_ABC1234567.p8
  ```
- **或 Apple ID / FASTLANE_SESSION**
  ```bash
  export FASTLANE_USER="your_apple_id@example.com"
  export FASTLANE_SESSION="..."
  ```

## 注意
- Xcode 打开 SwiftPM 工程与传统 .xcodeproj 等价可运行。
- `resign` 需本机钥匙串有可用的 AdHoc/Distribution 证书与私钥。
- 你的后端需提供 `/api/signer/next|status|result` 等接口。
