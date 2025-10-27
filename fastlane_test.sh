#!/bin/bash

# 简化的fastlane签名测试脚本

echo "🚀 Fastlane签名测试"
echo "=================="
echo ""

# 参数设置
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="com.si4key.si4ilocker2"
DEVICE_UUID="00008120-001A10513622201E"

echo "📋 测试参数:"
echo "IPA: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Device UUID: $DEVICE_UUID"
echo ""

# 检查文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在"
    exit 1
fi

echo "✅ IPA文件存在"
echo ""

# 检查fastlane环境
if [ ! -d "fastlane" ]; then
    echo "❌ fastlane目录不存在"
    exit 1
fi

echo "✅ fastlane目录存在"
echo ""

# 进入fastlane目录
cd fastlane

# 检查依赖
echo "🔍 检查bundle依赖..."
if ! bundle check > /dev/null 2>&1; then
    echo "⚠️  依赖不完整，安装中..."
    bundle install
fi

echo "✅ Bundle依赖完整"
echo ""

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

# 重要：需要设置Apple ID凭证
echo "⚠️  重要: 请设置Apple ID凭证"
echo ""
echo "请选择凭证设置方式:"
echo "1) 使用Apple ID + 密码"
echo "2) 使用Session Token"
echo "3) 跳过凭证设置 (仅测试命令)"
echo ""
read -p "请选择 (1/2/3): " choice

case $choice in
    1)
        read -p "请输入Apple ID: " apple_id
        read -s -p "请输入密码: " password
        echo ""
        export FASTLANE_USER="$apple_id"
        export FASTLANE_PASSWORD="$password"
        ;;
    2)
        read -p "请输入Session Token: " session_token
        export FASTLANE_SESSION="$session_token"
        ;;
    3)
        echo "跳过凭证设置"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""

# 测试1: 登录验证
echo "🔐 测试1: 登录验证"
echo "=================="
echo "命令: bundle exec fastlane login"
echo ""

if [ "$choice" != "3" ]; then
    bundle exec fastlane login
    login_result=$?
    if [ $login_result -eq 0 ]; then
        echo "✅ 登录成功"
    else
        echo "❌ 登录失败 (退出代码: $login_result)"
    fi
else
    echo "⚠️  跳过登录测试"
fi

echo ""

# 测试2: 设备注册
echo "📱 测试2: 设备注册"
echo "=================="
export UDID="$DEVICE_UUID"
export BUNDLE_ID="$BUNDLE_ID"
export AUTO_SIGH="0"

echo "环境变量:"
echo "UDID=$UDID"
echo "BUNDLE_ID=$BUNDLE_ID"
echo ""
echo "命令: bundle exec fastlane register_udid"
echo ""

if [ "$choice" != "3" ]; then
    bundle exec fastlane register_udid
    register_result=$?
    if [ $register_result -eq 0 ]; then
        echo "✅ 设备注册成功"
    else
        echo "❌ 设备注册失败 (退出代码: $register_result)"
    fi
else
    echo "⚠️  跳过设备注册测试"
fi

echo ""

# 测试3: IPA签名
echo "✍️  测试3: IPA签名"
echo "================"
export IPA_PATH="$IPA_PATH"

echo "环境变量:"
echo "IPA_PATH=$IPA_PATH"
echo "BUNDLE_ID=$BUNDLE_ID"
echo ""
echo "命令: bundle exec fastlane resign_ipa"
echo ""

if [ "$choice" != "3" ]; then
    echo "🚀 开始IPA重签名..."
    bundle exec fastlane resign_ipa
    resign_result=$?
    if [ $resign_result -eq 0 ]; then
        echo "✅ IPA签名成功"
        
        # 查找输出文件
        echo ""
        echo "🔍 查找签名后的IPA文件..."
        find /tmp -name "*resigned*.ipa" -newer "$IPA_PATH" 2>/dev/null | head -5
        
    else
        echo "❌ IPA签名失败 (退出代码: $resign_result)"
    fi
else
    echo "⚠️  跳过IPA签名测试"
fi

echo ""
echo "📊 测试完成"
echo "==========="

if [ "$choice" != "3" ]; then
    echo "如果所有步骤都成功，说明签名环境正常"
    echo "如果有失败，请检查对应的错误信息"
else
    echo "要进行实际测试，请重新运行并提供真实凭证"
fi

echo ""
echo "💡 下一步:"
echo "1. 查看上面的错误信息"
echo "2. 检查Fastfile配置"
echo "3. 确认证书和Profile配置"