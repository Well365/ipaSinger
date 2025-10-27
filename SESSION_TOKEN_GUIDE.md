# 🔐 获取Apple ID Session Token指导

获取Apple ID Session Token有以下几种方法：

## 方法1: 使用fastlane spaceauth（推荐）

```bash
# 1. 安装fastlane（如果还没安装）
gem install fastlane

# 2. 运行spaceauth命令
fastlane spaceauth -u your-apple-id@example.com

# 3. 按照提示输入密码和双因素认证码
# 4. 复制生成的session token
```

## 方法2: 从浏览器获取

1. 打开浏览器，访问 https://appstoreconnect.apple.com
2. 登录你的Apple ID
3. 打开浏览器开发者工具（F12）
4. 切换到 Application/Storage 标签
5. 在 Cookies 中找到 `myacinfo` 字段
6. 复制其值，这就是session token

## 方法3: 从Xcode获取

1. 打开Xcode
2. 进入 Preferences > Accounts
3. 选择你的Apple ID账号
4. 右键选择 "Export Developer ID"
5. 在弹出的对话框中可以找到session信息

## 使用Session Token

获取到token后，可以这样使用：

```bash
# 设置环境变量
export FASTLANE_SESSION="your-session-token-here"

# 或者在脚本中使用
FASTLANE_SESSION="your-session-token-here" bundle exec fastlane your_lane
```

## 注意事项

- Session Token通常24-48小时后过期
- 建议定期更新token
- 不要在公开代码中硬编码token
- 可以保存在keychain或环境变量中

## 验证Token有效性

```bash
# 运行这个命令验证token是否有效
cd fastlane
export FASTLANE_SESSION="your-token"
bundle exec fastlane login
```

如果登录成功，说明token有效。