#!/bin/bash

# 🎯 完整的FastLane重签名测试
# 这个脚本将逐步测试每个环节，帮助你理解整个流程

echo "🎯 FastLane重签名完整测试"
echo "========================"
echo ""

# 检查是否在正确的目录
if [ ! -d "fastlane" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

echo "📋 配置信息"
echo "==========="
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
DEVICE_UUID="00008120-001A10513622201E"
SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"

echo "IPA文件: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "设备UDID: $DEVICE_UUID"
echo "签名身份: $SIGN_IDENTITY"
echo ""

# 检查IPA文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在: $IPA_PATH"
    echo "请确认文件路径正确"
    exit 1
fi

echo "✅ IPA文件存在"
echo ""

# 提示用户设置凭证
echo "🔑 Apple ID凭证设置"
echo "=================="
echo ""
echo "⚠️  重要: 需要Apple ID凭证才能继续"
echo ""
echo "方式1: Apple ID + 密码"
echo "export FASTLANE_USER=\"your-apple-id@example.com\""
echo "export FASTLANE_PASSWORD=\"your-password\""
echo ""
echo "方式2: Session Token (推荐)"
echo "export FASTLANE_SESSION=\"your-session-token\""
echo ""
echo "获取Session Token:"
echo "1. 运行: fastlane spaceauth -u your-apple-id@example.com"
echo "2. 或查看: SESSION_TOKEN_GUIDE.md"
echo ""

# 检查是否设置了凭证
if [ -z "$FASTLANE_USER" ] && [ -z "$FASTLANE_SESSION" ]; then
    echo "❌ 未检测到凭证"
    echo ""
    echo "请设置凭证后重新运行:"
    echo ""
    echo "# 使用Session Token"
    echo "export FASTLANE_SESSION=\"your-token\""
    echo "./test_complete_flow.sh"
    echo ""
    echo "# 或使用Apple ID"
    echo "export FASTLANE_USER=\"your-apple-id@example.com\""
    echo "export FASTLANE_PASSWORD=\"your-password\""
    echo "./test_complete_flow.sh"
    exit 1
fi

echo "✅ 检测到凭证设置"
if [ -n "$FASTLANE_SESSION" ]; then
    echo "使用Session Token"
elif [ -n "$FASTLANE_USER" ]; then
    echo "使用Apple ID: $FASTLANE_USER"
fi
echo ""

# 设置环境变量
echo "🔧 设置环境变量"
echo "=============="

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
export AUTO_SIGH="1"

echo "✅ 环境变量设置完成"
echo ""

# 进入fastlane目录
cd fastlane

echo "🧪 开始测试流程"
echo "=============="
echo ""

# 步骤1: 测试登录
echo "步骤1: 登录验证"
echo "-------------"
echo "命令: bundle exec fastlane login"
echo ""

bundle exec fastlane login
login_result=$?

if [ $login_result -eq 0 ]; then
    echo "✅ 登录成功"
else
    echo "❌ 登录失败"
    echo ""
    echo "可能的原因："
    echo "1. Apple ID或密码错误"
    echo "2. Session Token过期"
    echo "3. 网络连接问题"
    echo "4. 需要双因素认证"
    echo ""
    echo "解决方法："
    echo "1. 检查凭证是否正确"
    echo "2. 重新获取Session Token"
    echo "3. 尝试使用应用专用密码"
    exit 1
fi

echo ""

# 步骤2: 设备注册
echo "步骤2: 设备注册"
echo "-------------"
echo "命令: bundle exec fastlane register_udid"
echo ""

bundle exec fastlane register_udid
register_result=$?

if [ $register_result -eq 0 ]; then
    echo "✅ 设备注册成功"
else
    echo "❌ 设备注册失败"
    echo ""
    echo "可能的原因："
    echo "1. UDID格式错误"
    echo "2. 设备已注册满额"
    echo "3. 权限不足"
    echo ""
    echo "解决方法："
    echo "1. 检查UDID格式"
    echo "2. 清理不用的设备"
    echo "3. 确认开发者账号权限"
    exit 1
fi

echo ""

# 步骤3: IPA重签名
echo "步骤3: IPA重签名"
echo "-------------"
echo "命令: bundle exec fastlane resign_ipa"
echo ""

bundle exec fastlane resign_ipa
resign_result=$?

if [ $resign_result -eq 0 ]; then
    echo "✅ IPA重签名成功"
    
    echo ""
    echo "🔍 查找输出文件"
    echo "============="
    
    if [ -d "./out" ]; then
        echo "输出目录内容:"
        ls -la ./out/
        
        echo ""
        echo "重签名的IPA文件:"
        find ./out -name "*resigned*.ipa" -exec ls -lh {} \;
        
        # 验证签名
        resigned_ipa=$(find ./out -name "*resigned*.ipa" | head -1)
        if [ -n "$resigned_ipa" ]; then
            echo ""
            echo "🔍 验证重签名结果"
            echo "================"
            
            # 创建临时目录验证
            temp_dir="/tmp/verify_resign_$$"
            mkdir -p "$temp_dir"
            
            echo "解压重签名的IPA..."
            cd "$temp_dir"
            unzip -q "$resigned_ipa"
            
            if [ -d "Payload" ]; then
                app_path=$(find Payload -name "*.app" | head -1)
                if [ -n "$app_path" ]; then
                    echo "验证签名信息:"
                    codesign -dv "$app_path" 2>&1 | head -10
                    
                    echo ""
                    echo "验证签名有效性:"
                    codesign -v "$app_path" 2>&1
                    verify_result=$?
                    
                    if [ $verify_result -eq 0 ]; then
                        echo "✅ 签名验证成功"
                    else
                        echo "⚠️  签名验证有警告"
                    fi
                fi
            fi
            
            # 清理
            rm -rf "$temp_dir"
        fi
    else
        echo "⚠️  未找到输出目录"
    fi
    
else
    echo "❌ IPA重签名失败"
    echo ""
    echo "可能的原因："
    echo "1. 证书不匹配"
    echo "2. Provisioning Profile问题"
    echo "3. Bundle ID不匹配"
    echo "4. IPA文件损坏"
    echo ""
    echo "解决方法："
    echo "1. 检查证书有效性"
    echo "2. 确认Bundle ID匹配"
    echo "3. 重新下载Provisioning Profile"
    exit 1
fi

echo ""
echo "🎉 完整流程测试成功！"
echo "=================="
echo ""
echo "📊 测试结果总结："
echo "├── ✅ 登录验证"
echo "├── ✅ 设备注册" 
echo "└── ✅ IPA重签名"
echo ""
echo "💡 下一步："
echo "1. 集成到Swift应用中"
echo "2. 添加用户界面"
echo "3. 实现错误处理"
echo "4. 添加进度显示"
echo ""
echo "🔧 成功的环境变量配置："
echo "export LANG=\"en_US.UTF-8\""
echo "export LC_ALL=\"en_US.UTF-8\""
echo "export FASTLANE_DISABLE_COLORS=\"1\""
echo "export FASTLANE_SKIP_UPDATE_CHECK=\"1\""
echo "export FASTLANE_OPT_OUT_USAGE=\"1\""
echo "export IPA_PATH=\"$IPA_PATH\""
echo "export BUNDLE_ID=\"$BUNDLE_ID\""
echo "export UDID=\"$UDID\""
echo "export SIGN_IDENTITY=\"$SIGN_IDENTITY\""
echo "export AUTO_SIGH=\"1\""

if [ -n "$FASTLANE_SESSION" ]; then
    echo "export FASTLANE_SESSION=\"[YOUR_SESSION_TOKEN]\""
elif [ -n "$FASTLANE_USER" ]; then
    echo "export FASTLANE_USER=\"$FASTLANE_USER\""
    echo "export FASTLANE_PASSWORD=\"[YOUR_PASSWORD]\""
fi