#!/bin/bash

echo "🚨 深度问题分析"
echo "=============="
echo ""

echo "既然连续生成的应用专用密码都无法工作，问题可能更复杂..."
echo ""

echo "📋 请回答以下关键问题："
echo ""

read -p "1. 你能用主密码在 https://appleid.apple.com 登录吗？(y/n): " can_login_main
read -p "2. 这个账号开启了双重认证吗？(y/n): " has_2fa
read -p "3. 在Apple ID设置中看到「应用专用密码」选项了吗？(y/n): " can_see_app_passwords
read -p "4. 生成密码时有任何错误提示吗？(y/n): " had_generation_errors

echo ""

if [ "$can_login_main" != "y" ]; then
    echo "❌ 主密码登录问题"
    echo "首先解决Apple ID主账号登录问题"
    exit 1
fi

if [ "$has_2fa" != "y" ]; then
    echo "❌ 双重认证未开启"
    echo "应用专用密码需要双重认证支持"
    echo ""
    echo "解决方案："
    echo "1. 在Apple ID设置中开启双重认证"
    echo "2. 重新生成应用专用密码"
    exit 1
fi

if [ "$can_see_app_passwords" != "y" ]; then
    echo "❌ 无法看到应用专用密码选项"
    echo "这表示账号配置有问题"
    exit 1
fi

if [ "$had_generation_errors" = "y" ]; then
    echo "⚠️  生成过程有错误"
    echo "这可能是根本原因"
    exit 1
fi

echo "🔍 基础配置看起来正常，进行更深入的测试..."
echo ""

echo "测试1: 使用浏览器验证"
echo "==================="
echo ""
echo "请在浏览器中进行以下测试："
echo ""
echo "1. 访问: https://developer.apple.com"
echo "2. 点击右上角登录"
echo "3. 输入 Apple ID: copybytes@163.com"
echo "4. 输入主密码（不是应用专用密码）"
echo "5. 完成双重认证"
echo ""

read -p "能成功登录开发者门户吗？(y/n): " can_login_dev_portal

if [ "$can_login_dev_portal" != "y" ]; then
    echo "❌ 无法登录开发者门户"
    echo ""
    echo "可能原因："
    echo "1. 账号未激活开发者权限"
    echo "2. 开发者协议未签署"
    echo "3. 账号被暂停"
    echo "4. 地区限制"
    echo ""
    exit 1
fi

echo ""
echo "测试2: 手动设备注册"
echo "=================="
echo ""
echo "既然自动化失败，我们测试手动流程："
echo ""
echo "在开发者门户中："
echo "1. 进入 Certificates, Identifiers & Profiles"
echo "2. 选择 Devices"
echo "3. 点击 + 号添加新设备"
echo "4. 输入 UDID: 00008120-001A10513622201E"
echo "5. 输入设备名称"
echo ""

read -p "能手动添加设备吗？(y/n): " can_manual_add

if [ "$can_manual_add" = "y" ]; then
    echo "✅ 手动添加设备成功"
    echo ""
    echo "这说明："
    echo "1. 开发者账号正常"
    echo "2. 问题在于FastLane/Spaceship认证"
    echo ""
    echo "解决方案："
    echo "1. 使用手动设备注册"
    echo "2. 然后进行IPA重签名"
    echo ""
    echo "跳过自动注册，直接重签名IPA："
    echo "cd fastlane && bundle exec fastlane resign_ipa_skip_registration"
    echo ""
else
    echo "❌ 手动添加也失败"
    echo "说明开发者账号本身有问题"
fi

echo ""
echo "测试3: 应用专用密码格式测试"
echo "========================"
echo ""
echo "请再次输入应用专用密码："
read -s app_password
echo ""

# 检查各种可能的格式问题
echo "检查密码特征："
echo "原始密码: '$app_password'"
echo "长度: ${#app_password}"
echo "字符数: $(echo -n "$app_password" | wc -c)"

# 检查是否有隐藏字符
if command -v xxd >/dev/null 2>&1; then
    echo "十六进制: $(echo -n "$app_password" | xxd -p)"
fi

# 尝试清理密码
cleaned_password=$(echo "$app_password" | tr -d '[:space:]' | tr -d '\r\n')
echo "清理后: '$cleaned_password'"

if [ "$app_password" != "$cleaned_password" ]; then
    echo "⚠️  发现多余的空白字符"
    echo "使用清理后的密码重试"
    app_password="$cleaned_password"
fi

echo ""
echo "测试4: 替代认证方法"
echo "=================="
echo ""

cd fastlane

# 尝试使用API Key认证
echo "检查是否有API Key文件..."
if ls ../AuthKey_*.p8 2>/dev/null; then
    echo "✅ 发现API Key文件"
    echo "可以使用API Key认证替代密码认证"
    echo ""
    echo "修改Fastfile使用API Key认证："
    echo "app_store_connect_api_key("
    echo "  key_id: \"你的Key ID\","
    echo "  issuer_id: \"你的Issuer ID\","
    echo "  key_filepath: \"../AuthKey_XXX.p8\""
    echo ")"
else
    echo "📱 未找到API Key文件"
    echo ""
    echo "创建API Key的步骤："
    echo "1. 访问 https://appstoreconnect.apple.com/access/api"
    echo "2. 生成新的API Key"
    echo "3. 下载.p8文件"
    echo "4. 记录Key ID和Issuer ID"
fi

echo ""
echo "📊 最终诊断结果"
echo "=============="
echo ""

if [ "$can_login_dev_portal" = "y" ] && [ "$can_manual_add" = "y" ]; then
    echo "✅ 开发者账号正常"
    echo "❌ FastLane/Spaceship认证失败"
    echo ""
    echo "🎯 推荐解决方案："
    echo ""
    echo "方案1: 手动设备注册 + 自动重签名"
    echo "- 在开发者门户手动注册设备"
    echo "- 使用FastLane重签名IPA"
    echo ""
    echo "方案2: 使用API Key认证"
    echo "- 生成App Store Connect API Key"
    echo "- 替代应用专用密码认证"
    echo ""
    echo "方案3: 等待和重试"
    echo "- 等待24小时后重试"
    echo "- Apple服务器可能有临时问题"
    echo ""
else
    echo "❌ 开发者账号配置有问题"
    echo ""
    echo "需要先解决账号基础问题："
    echo "1. 确认账号类型和权限"
    echo "2. 签署必要协议"
    echo "3. 联系Apple Support"
fi