#!/bin/bash

# 🔐 Apple ID + 密码方式的详细流程指导
echo "🔐 Apple ID + 密码方式的FastLane签名流程"
echo "======================================="
echo ""

echo "📋 前置准备"
echo "=========="
echo "1. 确保Apple ID开启了双因素认证"
echo "2. 生成应用专用密码（推荐）"
echo "3. 确认开发者账号权限"
echo ""

echo "🔑 第一步：生成应用专用密码（重要！）"
echo "=================================="
echo ""
echo "为什么需要应用专用密码？"
echo "- Apple ID开启双因素认证后，第三方应用无法直接使用主密码"
echo "- 应用专用密码是专门为第三方应用生成的独立密码"
echo "- 更安全，可以随时撤销"
echo ""
echo "生成步骤："
echo "1. 访问 https://appleid.apple.com"
echo "2. 登录你的Apple ID"
echo "3. 进入「登录和安全」部分"
echo "4. 找到「应用专用密码」"
echo "5. 点击「生成密码」"
echo "6. 输入标签名称（例如：FastLane-IPA-Signer）"
echo "7. 复制生成的密码（格式如：xxxx-xxxx-xxxx-xxxx）"
echo ""

read -p "是否已经生成了应用专用密码？(y/n): " has_app_password

if [ "$has_app_password" != "y" ]; then
    echo ""
    echo "⚠️  请先生成应用专用密码，然后重新运行此脚本"
    echo ""
    echo "快速链接: https://appleid.apple.com/account/manage"
    exit 1
fi

echo ""
echo "🔧 第二步：设置凭证信息"
echo "===================="
echo ""

# read -p "请输入你的Apple ID: " apple_id
# echo ""
# echo "请输入应用专用密码（不是主密码）:"
# read -s app_password
# echo ""

# 验证输入
# if [ -z "$apple_id" ] || [ -z "$app_password" ]; then
#     echo "❌ Apple ID或密码不能为空"
#     exit 1
# fi

echo "✅ 凭证信息已输入"
echo ""

echo "🔧 第三步：设置环境变量"
echo "===================="

# 基本参数
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="happy.foxglobal.com585471"
DEVICE_UUID="00008120-001A10513622201E"
SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

# Apple ID凭证
export FASTLANE_USER="copybytes@163.com"
export FASTLANE_PASSWORD="avcf-ufri-tcvs-ibet"

# 签名相关变量
export IPA_PATH="$IPA_PATH"
export BUNDLE_ID="$BUNDLE_ID"
export UDID="$DEVICE_UUID"
export SIGN_IDENTITY="$SIGN_IDENTITY"
export AUTO_SIGH="1"

echo "环境变量设置完成："
echo "FASTLANE_USER=$apple_id"
echo "FASTLANE_PASSWORD=[隐藏]"
echo "IPA_PATH=$IPA_PATH"
echo "BUNDLE_ID=$BUNDLE_ID"
echo "UDID=$DEVICE_UUID"
echo "SIGN_IDENTITY=$SIGN_IDENTITY"
echo ""

# 检查IPA文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在: $IPA_PATH"
    echo "请确认文件路径正确"
    exit 1
fi

echo "✅ IPA文件检查通过"
echo ""

# 进入fastlane目录
if [ ! -d "fastlane" ]; then
    echo "❌ fastlane目录不存在"
    exit 1
fi

cd fastlane

echo "🧪 第四步：逐步执行签名流程"
echo "========================="
echo ""

# 步骤1: 测试登录
echo "步骤4.1: 登录验证"
echo "---------------"
echo "这一步会验证你的Apple ID凭证是否正确"
echo ""
echo "执行命令: bundle exec fastlane login"
echo ""

bundle exec fastlane login
login_result=$?

if [ $login_result -eq 0 ]; then
    echo ""
    echo "✅ 登录成功！Apple ID凭证有效"
else
    echo ""
    echo "❌ 登录失败"
    echo ""
    echo "常见问题及解决方法："
    echo "1. 使用了主密码而非应用专用密码"
    echo "   解决：生成并使用应用专用密码"
    echo ""
    echo "2. 应用专用密码格式错误"
    echo "   解决：确保密码格式为 xxxx-xxxx-xxxx-xxxx"
    echo ""
    echo "3. Apple ID输入错误"
    echo "   解决：检查邮箱地址是否正确"
    echo ""
    echo "4. 网络连接问题"
    echo "   解决：检查网络连接，尝试VPN"
    echo ""
    echo "5. Apple服务器问题"
    echo "   解决：稍后重试"
    exit 1
fi

echo ""
echo "等待3秒后继续下一步..."
sleep 3

# 步骤2: 设备注册
echo "步骤4.2: 设备注册"
echo "---------------"
echo "这一步会将设备UDID注册到你的开发者账号"
echo ""
echo "执行命令: bundle exec fastlane register_udid"
echo ""

bundle exec fastlane register_udid
register_result=$?

if [ $register_result -eq 0 ]; then
    echo ""
    echo "✅ 设备注册成功！"
else
    echo ""
    echo "❌ 设备注册失败"
    echo ""
    echo "常见问题及解决方法："
    echo "1. 设备已注册满额（免费账号100台，付费账号无限制）"
    echo "   解决：删除不用的设备或升级开发者账号"
    echo ""
    echo "2. UDID格式错误"
    echo "   解决：确认UDID格式正确（40位十六进制）"
    echo ""
    echo "3. 权限不足"
    echo "   解决：确认开发者账号有设备管理权限"
    echo ""
    echo "4. 设备已存在但Bundle ID不匹配"
    echo "   解决：检查Bundle ID配置"
    exit 1
fi

echo ""
echo "等待3秒后继续下一步..."
sleep 3

# 步骤3: IPA重签名
echo "步骤4.3: IPA重签名"
echo "---------------"
echo "这一步会下载证书配置文件并重新签名IPA"
echo ""
echo "执行命令: bundle exec fastlane resign_ipa"
echo ""

bundle exec fastlane resign_ipa
resign_result=$?

if [ $resign_result -eq 0 ]; then
    echo ""
    echo "✅ IPA重签名成功！"
    
    echo ""
    echo "🔍 查找输出文件"
    echo "============="
    
    if [ -d "./out" ]; then
        echo "输出目录内容:"
        ls -la ./out/
        
        echo ""
        resigned_files=$(find ./out -name "*resigned*.ipa")
        if [ -n "$resigned_files" ]; then
            echo "重签名的IPA文件:"
            echo "$resigned_files" | while read file; do
                echo "  📱 $(basename "$file")"
                echo "     大小: $(ls -lh "$file" | awk '{print $5}')"
                echo "     路径: $file"
                echo ""
            done
        else
            echo "⚠️  未找到重签名的IPA文件"
        fi
    else
        echo "⚠️  未找到输出目录"
    fi
    
else
    echo ""
    echo "❌ IPA重签名失败"
    echo ""
    echo "常见问题及解决方法："
    echo "1. 证书不匹配或过期"
    echo "   解决：检查开发者证书状态，重新生成证书"
    echo ""
    echo "2. Provisioning Profile下载失败"
    echo "   解决：检查网络连接，确认Bundle ID正确"
    echo ""
    echo "3. Bundle ID不匹配"
    echo "   解决：确认IPA的Bundle ID与设置一致"
    echo ""
    echo "4. 签名身份不可用"
    echo "   解决：检查证书是否安装在Keychain中"
    echo ""
    echo "5. IPA文件损坏"
    echo "   解决：重新下载IPA文件"
    exit 1
fi

echo ""
echo "🎉 完整流程执行成功！"
echo "==================="
echo ""
echo "📊 执行结果总结："
echo "├── ✅ Apple ID登录验证"
echo "├── ✅ 设备UDID注册"
echo "└── ✅ IPA重新签名"
echo ""
echo "💡 重要提示："
echo "1. 保存你的应用专用密码，下次可以重复使用"
echo "2. 应用专用密码可以在Apple ID管理页面撤销"
echo "3. 如果不再需要，建议定期更换密码"
echo ""
echo "🔧 保存成功的配置："
echo "export FASTLANE_USER=\"$apple_id\""
echo "export FASTLANE_PASSWORD=\"[你的应用专用密码]\""
echo "export IPA_PATH=\"$IPA_PATH\""
echo "export BUNDLE_ID=\"$BUNDLE_ID\""
echo "export UDID=\"$DEVICE_UUID\""
echo "export SIGN_IDENTITY=\"$SIGN_IDENTITY\""
echo ""
echo "下次可以直接使用这些环境变量，无需重新输入！"