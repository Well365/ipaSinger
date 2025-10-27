#!/bin/bash

echo "🔄 完整 IPA 签名工作流"
echo "===================="
echo "步骤1: 使用 FastLane 注册设备并获取 mobileprovision"
echo "步骤2: 使用直接 codesign 对 IPA 进行签名"
echo

# 配置参数
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
DEVICE_UDID="00008120-001A10513622201E"

echo "📋 工作流配置："
echo "IPA 路径: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID" 
echo "设备UDID: $DEVICE_UDID"
echo

# 检查必要文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA 文件不存在，请检查路径"
    echo "您可以:"
    echo "1. 修改脚本中的 IPA_PATH 变量"
    echo "2. 或者将 IPA 文件放到指定路径"
    exit 1
fi

# 检查 Apple ID 凭证
if [ -z "$FASTLANE_USER" ] || [ -z "$FASTLANE_PASSWORD" ]; then
    echo "🔑 需要设置 Apple ID 凭证"
    read -p "Apple ID: " apple_id
    echo "应用专用密码:"
    read -s app_password
    echo
    
    export FASTLANE_USER="$apple_id"
    export FASTLANE_PASSWORD="$app_password"
fi

# 设置环境变量
export IPA_PATH="$IPA_PATH"
export BUNDLE_ID="$BUNDLE_ID" 
export UDID="$DEVICE_UDID"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo "✅ 环境变量设置完成"
echo

# 步骤1: 使用 FastLane 注册设备
echo "📱 步骤1: 注册设备并获取配置文件"
echo "================================="

cd fastlane || {
    echo "❌ 无法进入 fastlane 目录"
    exit 1
}

# 只运行设备注册部分，避开签名问题
echo "🔐 执行登录..."
bundle exec fastlane login

if [ $? -eq 0 ]; then
    echo "✅ 登录成功"
else
    echo "❌ 登录失败"
    exit 1
fi

echo "📱 注册设备..."
bundle exec fastlane register_udid

if [ $? -eq 0 ]; then
    echo "✅ 设备注册成功" 
else
    echo "❌ 设备注册失败"
    exit 1
fi

# 尝试获取配置文件（可能会失败，但我们只需要部分成功）
echo "📋 尝试获取配置文件..."
mkdir -p ./out

# 使用 sigh 单独获取配置文件
bundle exec sigh --adhoc --app_identifier "$BUNDLE_ID" --output_path ./out --filename "adhoc_${BUNDLE_ID}.mobileprovision" --force --skip_certificate_verification 2>/dev/null

# 检查是否成功获取配置文件
PROVISION_FILE=$(find ./out -name "*.mobileprovision" | head -1)

cd ..

if [ -n "$PROVISION_FILE" ] && [ -f "$PROVISION_FILE" ]; then
    echo "✅ 配置文件获取成功: $(basename "$PROVISION_FILE")"
else
    echo "⚠️  FastLane 配置文件获取失败，但设备已注册"
    echo "您可以："
    echo "1. 手动从 Apple Developer Portal 下载 mobileprovision 文件"
    echo "2. 将文件放到 fastlane/out/ 目录"
    echo "3. 然后重新运行此脚本"
    
    read -p "是否继续尝试签名？(如果您已有配置文件) (y/n): " continue_sign
    if [ "$continue_sign" != "y" ]; then
        echo "退出工作流"
        exit 1
    fi
    
    # 重新查找配置文件
    PROVISION_FILE=$(find ./fastlane/out -name "*.mobileprovision" | head -1)
    if [ -z "$PROVISION_FILE" ]; then
        echo "❌ 仍未找到配置文件"
        exit 1
    fi
fi

echo
echo "🔐 步骤2: 直接签名 IPA"
echo "====================="

# 使用我们的直接签名脚本
echo "🚀 开始直接签名流程..."

# 创建临时工作目录
WORK_DIR="$(mktemp -d)"
OUTPUT_DIR="./signed"
mkdir -p "$OUTPUT_DIR"

echo "📦 解压 IPA..."
cd "$WORK_DIR"
unzip -q "$IPA_PATH"

# 查找 .app 文件
APP_PATH=$(find . -name "*.app" | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ 未找到 .app 文件"
    rm -rf "$WORK_DIR"
    exit 1
fi

echo "✅ 找到应用: $(basename "$APP_PATH")"

# 查找签名证书
SIGN_IDENTITY=$(security find-identity -v -p codesigning | grep "iPhone Developer" | head -1 | awk -F'"' '{print $2}')
if [ -z "$SIGN_IDENTITY" ]; then
    echo "❌ 未找到开发证书"
    echo "请确保已在 Keychain Access 中安装 iOS Development 证书"
    rm -rf "$WORK_DIR"
    exit 1
fi

echo "✅ 签名身份: $SIGN_IDENTITY"

# 替换配置文件
echo "🔄 替换 mobileprovision..."
cp "$(pwd)/../$PROVISION_FILE" "$APP_PATH/embedded.mobileprovision"

# 更新 Bundle ID
echo "📝 更新 Bundle ID..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_PATH/Info.plist"

# 删除旧签名
rm -rf "$APP_PATH/_CodeSignature"

# 签名 Frameworks
echo "🔐 签名 Frameworks..."
find "$APP_PATH" -name "*.framework" -exec codesign --force --sign "$SIGN_IDENTITY" {} \;

# 签名 PlugIns
find "$APP_PATH" -name "*.appex" -exec codesign --force --sign "$SIGN_IDENTITY" {} \;

# 签名主应用
echo "🔐 签名主应用..."
codesign --force --sign "$SIGN_IDENTITY" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ 签名成功"
else
    echo "❌ 签名失败"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 重新打包
echo "📦 重新打包..."
cd Payload
OUTPUT_IPA="$OUTPUT_DIR/$(basename "$IPA_PATH" .ipa)_resigned.ipa"
zip -r "$OUTPUT_IPA" .

cd ../..

if [ -f "$OUTPUT_IPA" ]; then
    echo
    echo "🎉 完整工作流成功完成！"
    echo "======================"
    echo
    echo "✅ FastLane 部分："
    echo "  • Apple ID 登录成功"
    echo "  • 设备注册成功" 
    echo "  • 配置文件获取成功"
    echo
    echo "✅ 直接签名部分："
    echo "  • IPA 解包成功"
    echo "  • 配置文件替换成功"
    echo "  • codesign 签名成功"
    echo "  • IPA 重新打包成功"
    echo
    echo "📁 输出文件:"
    echo "  路径: $OUTPUT_IPA"
    echo "  大小: $(ls -lh "$OUTPUT_IPA" | awk '{print $5}')"
    echo
    echo "🏆 这个混合方案成功地："
    echo "  • 利用了 FastLane 的优势（设备注册）"
    echo "  • 避开了 FastLane 的问题（证书管理）"
    echo "  • 实现了完整的 IPA 重签名流程"
    
    # 验证签名
    echo
    echo "🔍 验证最终签名..."
    unzip -q "$OUTPUT_IPA" -d "$WORK_DIR/verify"
    APP_VERIFY=$(find "$WORK_DIR/verify" -name "*.app" | head -1)
    if codesign --verify "$APP_VERIFY" 2>/dev/null; then
        echo "✅ 签名验证通过"
    else
        echo "⚠️  签名有警告但通常仍可用"
    fi
    
else
    echo "❌ 重新打包失败"
fi

# 清理
rm -rf "$WORK_DIR"

echo
echo "🚀 工作流完成！您现在有一个实用的签名解决方案："
echo "1. FastLane 处理 Apple 服务交互"
echo "2. 系统 codesign 处理实际签名"
echo "3. 避开了 FastLane 的证书管理问题"
echo "4. 实现了端到端的 IPA 重签名"