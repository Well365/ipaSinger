#!/bin/bash

# 直接IPA签名验证脚本
# 用于验证签名环境和流程

set -e  # 遇到错误立即退出

echo "🔧 直接IPA签名验证脚本"
echo "========================="
echo ""

# 从日志中提取的参数
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
DEVELOPER_ID="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"
DEVICE_UUID="00008120-001A10513622201E"

echo "📋 使用参数:"
echo "IPA路径: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Developer ID: $DEVELOPER_ID"
echo "Device UUID: $DEVICE_UUID"
echo ""

# 1. 环境检查
echo "🔍 步骤1: 环境检查"
echo "=================="

# 检查IPA文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在: $IPA_PATH"
    exit 1
fi

echo "✅ IPA文件存在"
IPA_SIZE=$(stat -f%z "$IPA_PATH")
echo "📦 IPA文件大小: $IPA_SIZE bytes ($(echo "scale=2; $IPA_SIZE/1024/1024" | bc) MB)"

# 检查Ruby环境
echo ""
echo "🔍 Ruby环境:"
which ruby || echo "❌ Ruby未找到"
ruby --version || echo "❌ Ruby版本检查失败"

echo ""
echo "🔍 Bundle环境:"
which bundle || echo "❌ Bundle未找到"

# 检查fastlane目录
echo ""
echo "🔍 Fastlane环境:"
if [ -d "fastlane" ]; then
    echo "✅ fastlane目录存在"
    
    if [ -f "fastlane/Gemfile" ]; then
        echo "✅ Gemfile存在"
    else
        echo "❌ Gemfile不存在"
    fi
    
    if [ -f "fastlane/Fastfile" ]; then
        echo "✅ Fastfile存在"
    else
        echo "❌ Fastfile不存在"
    fi
    
    # 检查bundle状态
    echo ""
    echo "🔍 检查bundle依赖:"
    cd fastlane
    if bundle check; then
        echo "✅ Bundle依赖完整"
    else
        echo "⚠️  Bundle依赖不完整，尝试安装..."
        bundle install
    fi
    cd ..
else
    echo "❌ fastlane目录不存在"
    exit 1
fi

# 检查证书
echo ""
echo "🔍 步骤2: 证书检查"
echo "=================="
echo "查找Developer ID对应的证书:"
security find-identity -v -p codesigning | grep "$DEVELOPER_ID" || echo "❌ 未找到指定的Developer ID"

echo ""
echo "所有可用的代码签名证书:"
security find-identity -v -p codesigning

# 2. 模拟登录流程
echo ""
echo "🔐 步骤3: 模拟登录验证"
echo "===================="

# 设置环境变量 (需要从钥匙串或配置中获取)
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

# 这里需要设置Apple ID相关的环境变量
# 注意：实际使用时需要设置真实的凭证
echo "⚠️  注意: 需要设置Apple ID凭证环境变量"
echo "建议设置:"
echo "export FASTLANE_USER=\"your-apple-id@example.com\""
echo "export FASTLANE_SESSION=\"your-session-token\""
echo "或者"
echo "export FASTLANE_PASSWORD=\"your-password\""

# 3. 模拟设备注册
echo ""
echo "📱 步骤4: 模拟设备注册"
echo "===================="

export UDID="$DEVICE_UUID"
export BUNDLE_ID="$BUNDLE_ID"
export AUTO_SIGH="0"

echo "环境变量设置:"
echo "UDID=$UDID"
echo "BUNDLE_ID=$BUNDLE_ID"
echo "AUTO_SIGH=$AUTO_SIGH"

echo ""
echo "模拟命令:"
echo "cd fastlane && bundle exec fastlane register_udid"

# 4. 模拟签名流程
echo ""
echo "✍️  步骤5: 模拟IPA签名"
echo "==================="

export IPA_PATH="$IPA_PATH"

echo "环境变量设置:"
echo "IPA_PATH=$IPA_PATH"
echo "BUNDLE_ID=$BUNDLE_ID"

echo ""
echo "模拟命令:"
echo "cd fastlane && bundle exec fastlane resign_ipa"

# 5. 手动签名测试 (使用codesign)
echo ""
echo "🔧 步骤6: 手动签名测试"
echo "===================="

# 创建临时目录
TEMP_DIR="/tmp/ipa_test_$(date +%s)"
mkdir -p "$TEMP_DIR"

echo "解压IPA到临时目录: $TEMP_DIR"
cd "$TEMP_DIR"
unzip -q "$IPA_PATH"

echo "查找Payload目录:"
if [ -d "Payload" ]; then
    echo "✅ Payload目录存在"
    APP_PATH=$(find Payload -name "*.app" | head -1)
    if [ -n "$APP_PATH" ]; then
        echo "✅ 找到app包: $APP_PATH"
        
        echo ""
        echo "查看当前签名信息:"
        codesign -vv -d "$APP_PATH" 2>&1 || echo "获取签名信息失败"
        
        echo ""
        echo "尝试验证签名:"
        codesign --verify --verbose "$APP_PATH" 2>&1 || echo "签名验证失败"
        
        echo ""
        echo "查看可用的签名身份:"
        security find-identity -v -p codesigning | head -5
        
        echo ""
        echo "🎯 可以尝试的手动重签名命令:"
        echo "codesign --force --sign \"$DEVELOPER_ID\" \"$APP_PATH\""
        
    else
        echo "❌ 未找到.app文件"
    fi
else
    echo "❌ 未找到Payload目录"
fi

# 清理
echo ""
echo "🧹 清理临时文件..."
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "📊 总结"
echo "======"
echo "1. 环境检查完成"
echo "2. 证书信息已显示"
echo "3. 手动测试命令已提供"
echo ""
echo "💡 下一步建议:"
echo "1. 确保Apple ID凭证正确设置"
echo "2. 在fastlane目录中手动运行命令测试"
echo "3. 检查Fastfile中的resign_ipa任务"
echo ""
echo "🔧 手动测试命令:"
echo "cd fastlane"
echo "export FASTLANE_USER=\"your-apple-id\""
echo "export FASTLANE_SESSION=\"your-session-token\""
echo "export IPA_PATH=\"$IPA_PATH\""
echo "export BUNDLE_ID=\"$BUNDLE_ID\""
echo "bundle exec fastlane resign_ipa"