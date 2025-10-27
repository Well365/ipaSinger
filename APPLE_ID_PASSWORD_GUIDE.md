# 🔐 Apple ID + 密码方式详细指导

## 概述

使用Apple ID + 密码方式是FastLane认证的传统方法，适合不想使用Session Token的情况。

## ⚠️ 重要提醒

**必须使用应用专用密码，不能使用Apple ID主密码！**

## 第一步：生成应用专用密码

### 为什么需要应用专用密码？

- Apple ID开启双因素认证后，第三方应用无法使用主密码
- 应用专用密码是专门为第三方应用生成的独立密码
- 更安全，可以随时撤销，不影响主账号

### 生成步骤

1. **访问Apple ID管理页面**
   - 打开浏览器访问：https://appleid.apple.com
   - 使用你的Apple ID登录

2. **进入安全设置**
   - 找到「登录和安全」(Sign-In and Security)部分
   - 点击进入

3. **生成应用专用密码**
   - 找到「应用专用密码」(App-Specific Passwords)部分
   - 点击「生成密码...」(Generate Password...)
   - 输入密码标签，例如：`FastLane-IPA-Signer`
   - 点击「创建」(Create)

4. **保存密码**
   - 复制显示的密码（格式：`xxxx-xxxx-xxxx-xxxx`）
   - **立即保存**，关闭页面后无法再次查看
   - 建议保存在密码管理器中

### 应用专用密码格式示例
```
abcd-efgh-ijkl-mnop
```

## 第二步：使用流程

### 快速开始
```bash
# 运行指导脚本
./apple_id_password_flow.sh
```

### 手动设置步骤

1. **设置环境变量**
```bash
export FASTLANE_USER="your-apple-id@example.com"
export FASTLANE_PASSWORD="abcd-efgh-ijkl-mnop"  # 应用专用密码
```

2. **设置其他必需变量**
```bash
export IPA_PATH="/path/to/your/app.ipa"
export BUNDLE_ID="com.yourcompany.yourapp"
export UDID="your-device-udid"
export SIGN_IDENTITY="your-certificate-id"
```

3. **执行签名**
```bash
cd fastlane
bundle exec fastlane login
bundle exec fastlane register_udid
bundle exec fastlane resign_ipa
```

## 第三步：常见问题解决

### 问题1：登录失败
**错误信息**：`Invalid username and password combination`

**可能原因**：
- 使用了主密码而不是应用专用密码
- 应用专用密码格式错误
- Apple ID输入错误

**解决方法**：
1. 确认使用的是应用专用密码（格式：xxxx-xxxx-xxxx-xxxx）
2. 检查Apple ID邮箱地址是否正确
3. 重新生成应用专用密码

### 问题2：双因素认证提示
**错误信息**：要求输入验证码

**解决方法**：
- 应用专用密码正确配置后不应该出现此提示
- 如果出现，说明可能使用了主密码
- 重新设置应用专用密码

### 问题3：设备注册失败
**错误信息**：`Device registration failed`

**可能原因**：
- 设备数量达到上限（免费账号100台）
- UDID格式错误
- 权限不足

**解决方法**：
1. 检查开发者账号设备数量
2. 验证UDID格式（40位十六进制）
3. 确认账号权限

### 问题4：证书签名失败
**错误信息**：`Code signing failed`

**可能原因**：
- 证书过期或无效
- Bundle ID不匹配
- Provisioning Profile问题

**解决方法**：
1. 检查证书有效期
2. 确认Bundle ID匹配
3. 重新生成Provisioning Profile

## 第四步：安全建议

### 密码管理
- 应用专用密码保存在安全的密码管理器中
- 定期更换应用专用密码
- 不在代码中硬编码密码

### 撤销密码
如果不再需要或怀疑泄露：
1. 访问 https://appleid.apple.com
2. 进入「登录和安全」
3. 在「应用专用密码」中找到对应密码
4. 点击「撤销」

### 环境变量安全
```bash
# 好的做法：使用环境变量
export FASTLANE_PASSWORD="$(cat ~/.fastlane_password)"

# 不好的做法：硬编码在脚本中
export FASTLANE_PASSWORD="abcd-efgh-ijkl-mnop"
```

## 第五步：集成到应用

将成功的配置集成到Swift应用中：

```swift
// 在Swift中设置环境变量
var env = ProcessInfo.processInfo.environment
env["FASTLANE_USER"] = credential.appleId
env["FASTLANE_PASSWORD"] = credential.appSpecificPassword
env["IPA_PATH"] = ipaPath
env["BUNDLE_ID"] = bundleId
// ... 其他变量
```

## 总结

Apple ID + 密码方式的关键点：
1. ✅ 必须使用应用专用密码
2. ✅ 确保双因素认证已开启
3. ✅ 妥善保管应用专用密码
4. ✅ 定期检查和更新密码
5. ✅ 测试完整流程后再集成到应用

成功配置后，这种方式稳定可靠，适合长期使用。