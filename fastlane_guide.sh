#!/bin/bash

# 详细的FastLane重签名流程指导
echo "🎯 FastLane重签名详细流程指导"
echo "================================"
echo ""

echo "📋 准备工作检查清单："
echo "├── ✅ IPA文件存在"
echo "├── ✅ 开发者证书可用"
echo "├── ✅ Bundle环境正常"
echo "└── ⚠️  需要Apple ID凭证"
echo ""

echo "🔑 第一步：设置Apple ID凭证"
echo "========================="
echo ""
echo "方式1: 使用Apple ID + 密码"
echo "export FASTLANE_USER=\"your-apple-id@example.com\""
echo "export FASTLANE_PASSWORD=\"your-password\""
echo ""
echo "方式2: 使用Session Token (推荐)"
echo "export FASTLANE_SESSION=\"your-session-token\""
echo ""
echo "获取Session Token的方法："
echo "1. 在另一台已登录的设备上运行 'fastlane spaceauth'"
echo "2. 或者从浏览器开发者工具中获取myacinfo cookie"
echo ""

read -p "您想要输入凭证吗？(y/n): " setup_creds

if [ "$setup_creds" = "y" ] || [ "$setup_creds" = "Y" ]; then
    echo ""
    echo "请选择凭证类型："
    echo "1) Apple ID + 密码"
    echo "2) Session Token"
    echo "3) 跳过（稍后手动设置）"
    
    read -p "请选择 (1/2/3): " cred_type
    
    case $cred_type in
        1)
            read -p "请输入Apple ID: " apple_id
            read -s -p "请输入密码: " password
            echo ""
            export FASTLANE_USER="$apple_id"
            export FASTLANE_PASSWORD="$password"
            echo "✅ Apple ID凭证已设置"
            ;;
        2)
            echo ""
            echo "💡 获取Session Token的方法："
            echo "方法1: fastlane spaceauth -u your-apple-id@example.com"
            echo "方法2: 从浏览器Cookie中获取myacinfo值"
            echo ""
            read -p "请输入Session Token: " session_token
            export FASTLANE_SESSION="$session_token"
            echo "✅ Session Token已设置"
            ;;
        3)
            echo "⚠️  请稍后手动设置凭证"
            ;;
    esac
fi

echo ""
echo "🔧 第二步：环境变量设置"
echo "===================="

# 基本参数
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
DEVICE_UUID="00008120-001A10513622201E"
SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"

# 设置所有必需的环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

# 签名相关变量
export IPA_PATH="$IPA_PATH"
export BUNDLE_ID="$BUNDLE_ID"
export UDID="$DEVICE_UUID"
export SIGN_IDENTITY="$SIGN_IDENTITY"
export AUTO_SIGH="1"  # 自动生成/下载AdHoc证书

echo "环境变量设置："
echo "IPA_PATH=$IPA_PATH"
echo "BUNDLE_ID=$BUNDLE_ID"
echo "UDID=$UDID"
echo "SIGN_IDENTITY=$SIGN_IDENTITY"
echo "AUTO_SIGH=$AUTO_SIGH"
echo ""

# 进入fastlane目录
cd fastlane || {
    echo "❌ fastlane目录不存在"
    exit 1
}

echo "🔍 第三步：逐步测试流程"
echo "===================="
echo ""

echo "步骤3.1: 测试登录"
echo "----------------"
echo "命令: bundle exec fastlane login"
echo ""

if [ -n "$FASTLANE_USER" ] || [ -n "$FASTLANE_SESSION" ]; then
    echo "🚀 执行登录测试..."
    bundle exec fastlane login
    login_result=$?
    
    if [ $login_result -eq 0 ]; then
        echo "✅ 登录成功！"
    else
        echo "❌ 登录失败，请检查凭证"
        echo ""
        echo "常见问题解决："
        echo "1. 检查Apple ID和密码是否正确"
        echo "2. 确认Apple ID开启了双因素认证"
        echo "3. 尝试使用应用专用密码"
        echo "4. 检查网络连接"
        exit 1
    fi
else
    echo "⚠️  跳过登录测试（未设置凭证）"
fi

echo ""
echo "步骤3.2: 测试设备注册"
echo "-------------------"
echo "命令: bundle exec fastlane register_udid"
echo ""

if [ -n "$FASTLANE_USER" ] || [ -n "$FASTLANE_SESSION" ]; then
    echo "🚀 执行设备注册..."
    bundle exec fastlane register_udid
    register_result=$?
    
    if [ $register_result -eq 0 ]; then
        echo "✅ 设备注册成功！"
    else
        echo "❌ 设备注册失败"
        echo ""
        echo "常见问题解决："
        echo "1. 检查UDID格式是否正确"
        echo "2. 确认开发者账号有权限注册设备"
        echo "3. 检查设备是否已经注册过"
        exit 1
    fi
else
    echo "⚠️  跳过设备注册测试（未设置凭证）"
fi

echo ""
echo "步骤3.3: 测试IPA重签名"
echo "--------------------"
echo "命令: bundle exec fastlane resign_ipa"
echo ""

if [ -n "$FASTLANE_USER" ] || [ -n "$FASTLANE_SESSION" ]; then
    echo "🚀 执行IPA重签名..."
    bundle exec fastlane resign_ipa
    resign_result=$?
    
    if [ $resign_result -eq 0 ]; then
        echo "✅ IPA重签名成功！"
        
        echo ""
        echo "🔍 查找输出文件..."
        if [ -d "./out" ]; then
            find ./out -name "*resigned*.ipa" -exec ls -la {} \;
        fi
        
        echo ""
        echo "🎉 完整流程测试成功！"
        
    else
        echo "❌ IPA重签名失败"
        echo ""
        echo "常见问题解决："
        echo "1. 检查证书是否有效"
        echo "2. 确认Bundle ID匹配"
        echo "3. 检查Provisioning Profile"
        echo "4. 验证IPA文件完整性"
    fi
else
    echo "⚠️  跳过IPA重签名测试（未设置凭证）"
    echo ""
    echo "要完成测试，请设置凭证后重新运行"
fi

echo ""
echo "📊 流程总结"
echo "=========="
echo "如果所有步骤都成功，说明FastLane环境完全正常"
echo "如果有步骤失败，请根据错误信息进行调试"
echo ""
echo "💡 下一步建议："
echo "1. 保存成功的环境变量配置"
echo "2. 将流程集成到Swift应用中"
echo "3. 添加错误处理和用户界面"
echo ""
echo "🔧 手动命令参考："
echo "export FASTLANE_USER=\"your-apple-id@example.com\""
echo "export FASTLANE_SESSION=\"your-session-token\""
echo "cd fastlane"
echo "bundle exec fastlane login"
echo "bundle exec fastlane register_udid"
echo "bundle exec fastlane resign_ipa"