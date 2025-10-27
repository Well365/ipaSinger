#!/bin/bash

# 简化的fastlane测试 - 只测试resign_ipa

echo "🚀 简化测试 - 仅测试IPA重签名"
echo "================================"
echo ""

# 参数设置
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
DEVICE_UUID="00008120-001A10513622201E"
SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"

echo "📋 测试参数:"
echo "IPA: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Device UUID: $DEVICE_UUID"
echo "Sign Identity: $SIGN_IDENTITY"
echo ""

# 检查文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在"
    exit 1
fi

echo "✅ IPA文件存在"
echo ""

# 进入fastlane目录
cd fastlane

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

# IPA签名相关变量
export IPA_PATH="$IPA_PATH"
export BUNDLE_ID="$BUNDLE_ID"
export SIGN_IDENTITY="$SIGN_IDENTITY"

# 设置一个占位符session避免登录
export FASTLANE_SESSION="dummy_session_for_test"

echo "✍️  测试: IPA签名"
echo "================"
echo "环境变量:"
echo "IPA_PATH=$IPA_PATH"
echo "BUNDLE_ID=$BUNDLE_ID"
echo "SIGN_IDENTITY=$SIGN_IDENTITY"
echo ""
echo "命令: bundle exec fastlane resign_ipa"
echo ""

echo "🚀 开始IPA重签名..."
bundle exec fastlane resign_ipa

resign_result=$?
if [ $resign_result -eq 0 ]; then
    echo "✅ IPA签名成功"
    
    # 查找输出文件
    echo ""
    echo "🔍 查找签名后的IPA文件..."
    find ./out -name "*resigned*.ipa" 2>/dev/null
    
else
    echo "❌ IPA签名失败 (退出代码: $resign_result)"
fi

echo ""
echo "📊 测试完成"