#!/bin/bash

# 🔧 设备注册失败问题诊断和解决脚本

echo "🔍 设备注册失败问题诊断"
echo "======================"
echo ""

echo "📊 问题分析："
echo "✅ 登录验证通过 (login lane 成功)"
echo "❌ 设备注册失败 (register_device 失败)"
echo "🔍 错误: Invalid username and password combination"
echo ""

echo "💡 可能原因："
echo "1. Session过期 - FastLane session在操作间过期"
echo "2. 权限问题 - Apple ID没有设备管理权限"
echo "3. 账号类型 - 可能不是付费开发者账号"
echo "4. 两步验证 - 需要重新认证"
echo "5. Apple服务器 - 临时服务问题"
echo ""

UDID="00008120-001A10513622201E"
BUNDLE_ID="exam.duo.apih"

echo "📋 当前配置："
echo "UDID: $UDID"
echo "Bundle ID: $BUNDLE_ID"
echo "用户: copybytes@163.com"
echo ""

echo "🔧 解决方案尝试"
echo "=============="
echo ""

# 检查当前环境变量
if [ -z "$FASTLANE_USER" ]; then
    echo "⚠️  FASTLANE_USER 未设置"
    read -p "请输入Apple ID: " apple_id
    export FASTLANE_USER="$apple_id"
fi

if [ -z "$FASTLANE_PASSWORD" ]; then
    echo "⚠️  FASTLANE_PASSWORD 未设置"
    echo "请输入应用专用密码:"
    read -s app_password
    export FASTLANE_PASSWORD="$app_password"
    echo ""
fi

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"
export UDID="$UDID"
export BUNDLE_ID="$BUNDLE_ID"
export DEVICE_NAME="iPhone-$(echo $UDID | tail -c 7)"

cd fastlane || exit 1

echo "🧪 解决方案1: 清除缓存重新登录"
echo "=============================="
echo ""
echo "清除FastLane凭证缓存..."

# 清除可能的缓存
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*

echo "重新执行完整登录流程..."
echo ""

# 强制重新登录
bundle exec fastlane login
login_result=$?

if [ $login_result -eq 0 ]; then
    echo "✅ 重新登录成功"
    
    echo ""
    echo "立即尝试设备注册..."
    bundle exec fastlane register_udid
    register_result=$?
    
    if [ $register_result -eq 0 ]; then
        echo "✅ 设备注册成功！问题已解决"
        exit 0
    else
        echo "❌ 设备注册仍然失败，尝试下一个解决方案"
    fi
else
    echo "❌ 重新登录失败"
fi

echo ""
echo "🧪 解决方案2: 检查开发者账号状态"
echo "=============================="
echo ""

echo "正在检查开发者账号信息..."

# 尝试获取team信息
bundle exec fastlane run get_app_store_connect_api_key 2>/dev/null || {
    echo "无法获取API信息，使用直接方式检查..."
}

echo ""
echo "🧪 解决方案3: 手动验证设备信息"
echo "============================"
echo ""

# 验证UDID格式
if [[ $UDID =~ ^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$ ]]; then
    echo "✅ UDID格式正确: $UDID"
else
    echo "❌ UDID格式可能有问题: $UDID"
    echo "正确格式应该是: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
fi

echo ""
echo "🧪 解决方案4: 使用简化的注册方法"
echo "=============================="
echo ""

# 创建临时的简化注册文件
cat > temp_register.rb << 'EOF'
require 'spaceship'

begin
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "登录成功"
  
  # 获取可用的teams
  teams = Spaceship::Portal.client.teams
  puts "可用的团队:"
  teams.each do |team|
    puts "  - #{team['name']} (#{team['teamId']})"
  end
  
  # 尝试注册设备
  team_id = teams.first['teamId'] if teams.any?
  puts "使用团队: #{team_id}"
  
  device = Spaceship::Portal.device.create!(
    name: ENV['DEVICE_NAME'] || "Device-#{ENV['UDID'][-6..-1]}",
    udid: ENV['UDID']
  )
  
  puts "设备注册成功: #{device.name}"
  
rescue => e
  puts "错误: #{e.message}"
  puts "可能的原因:"
  puts "1. 账号不是付费开发者账号"
  puts "2. 没有设备管理权限"
  puts "3. 设备数量已达上限"
  puts "4. UDID已存在"
end
EOF

echo "运行简化注册脚本..."
bundle exec ruby temp_register.rb

rm -f temp_register.rb

echo ""
echo "🧪 解决方案5: 检查账号权限"
echo "========================"
echo ""

echo "请检查以下几点："
echo ""
echo "1. 开发者账号类型："
echo "   - 免费账号：无法注册设备到远程"
echo "   - 付费个人账号：可以注册100台设备"
echo "   - 付费企业账号：无设备数量限制"
echo ""
echo "2. 账号权限："
echo "   - 需要 Admin 或 App Manager 权限"
echo "   - Developer 权限可能不够"
echo ""
echo "3. 账号状态："
echo "   - 确认开发者账号处于有效状态"
echo "   - 检查是否有未完成的协议需要签署"
echo ""

echo "🔗 建议访问以下链接检查："
echo "1. Apple Developer Portal: https://developer.apple.com"
echo "2. 检查账号状态和权限"
echo "3. 查看设备列表和可用数量"
echo ""

echo "💡 临时解决方案："
echo "如果设备注册继续失败，可以："
echo "1. 手动在Apple Developer Portal注册设备"
echo "2. 使用已有的Provisioning Profile"
echo "3. 跳过设备注册，直接尝试签名"
echo ""

read -p "是否尝试跳过设备注册直接签名？(y/n): " skip_register

if [ "$skip_register" = "y" ]; then
    echo ""
    echo "🚀 跳过设备注册，直接尝试IPA签名"
    echo "==============================="
    
    export AUTO_SIGH="0"  # 不自动生成profile
    export IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
    export SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"
    
    echo "尝试使用现有配置直接签名..."
    bundle exec fastlane resign_ipa
    
    if [ $? -eq 0 ]; then
        echo "✅ IPA签名成功！"
        echo "说明环境配置正确，只是设备注册有问题"
    else
        echo "❌ IPA签名也失败"
        echo "需要进一步检查证书和Profile配置"
    fi
fi

echo ""
echo "📋 问题报告总结"
echo "=============="
echo "如果问题持续存在，请提供以下信息："
echo "1. 开发者账号类型（免费/付费个人/企业）"
echo "2. 账号权限级别"
echo "3. 当前已注册设备数量"
echo "4. 是否有其他设备成功注册过"