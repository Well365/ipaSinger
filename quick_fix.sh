#!/bin/bash

echo "🔧 快速设备注册问题修复"
echo "======================"
echo ""

echo "基于你的错误，让我们尝试几个快速解决方案："
echo ""

# 设置已知的环境变量
export FASTLANE_USER="copybytes@163.com"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"
export UDID="00008120-001A10513622201E"
export BUNDLE_ID="exam.duo.apih"
export SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"
export IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"

echo "请输入应用专用密码:"
read -s password
export FASTLANE_PASSWORD="$password"
echo ""

cd fastlane

echo "方案1: 跳过设备注册，直接签名"
echo "============================"
echo ""
echo "设置 AUTO_SIGH=0 跳过自动证书下载"

export AUTO_SIGH="0"

echo "尝试直接执行 resign_ipa..."
bundle exec fastlane resign_ipa

resign_result=$?

if [ $resign_result -eq 0 ]; then
    echo ""
    echo "🎉 成功！跳过设备注册后签名成功"
    echo "说明问题确实是设备注册权限问题"
    echo ""
    echo "解决方案:"
    echo "1. 手动在Apple Developer Portal注册设备"
    echo "2. 或者使用现有的Provisioning Profile"
    exit 0
fi

echo ""
echo "方案2: 尝试手动验证账号权限"
echo "=========================="
echo ""

# 创建简单的权限检查脚本
cat > check_permissions.rb << 'EOF'
require 'spaceship'

begin
  puts "正在连接Apple Developer Portal..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 登录成功"
  
  # 获取团队信息
  teams = Spaceship::Portal.client.teams
  puts "\n📊 账号信息:"
  teams.each do |team|
    puts "  团队: #{team['name']}"
    puts "  ID: #{team['teamId']}"
    puts "  类型: #{team['type']}"
    puts "  角色: #{team['currentTeamMember']['roles'].join(', ')}"
  end
  
  # 检查现有设备
  puts "\n📱 当前注册的设备:"
  devices = Spaceship::Portal.device.all
  puts "  总数: #{devices.count}"
  devices.first(5).each do |device|
    puts "  - #{device.name} (#{device.udid})"
  end
  
  if devices.count >= 100
    puts "⚠️  警告: 设备数量接近或达到限制(100台)"
  end
  
rescue => e
  puts "❌ 错误: #{e.message}"
  
  if e.message.include?("Invalid username and password")
    puts "\n可能原因:"
    puts "1. 应用专用密码过期"
    puts "2. 账号没有开发者权限"
    puts "3. 需要重新生成应用专用密码"
  end
end
EOF

echo "运行权限检查脚本..."
bundle exec ruby check_permissions.rb

rm -f check_permissions.rb

echo ""
echo "方案3: 检查现有Provisioning Profile"
echo "================================="
echo ""

echo "查找系统中的Provisioning Profile..."
find ~/Library/MobileDevice/Provisioning\ Profiles/ -name "*.mobileprovision" 2>/dev/null | head -5 | while read profile; do
    echo "找到Profile: $(basename "$profile")"
    # 简单检查bundle id
    if grep -q "exam.duo.apih" "$profile" 2>/dev/null; then
        echo "  ✅ 包含目标Bundle ID: exam.duo.apih"
    fi
done

echo ""
echo "💡 建议的解决步骤:"
echo "=================="
echo ""
echo "1. 【立即可行】手动注册设备:"
echo "   - 访问 https://developer.apple.com"
echo "   - 登录 copybytes@163.com"
echo "   - 进入 Certificates, Identifiers & Profiles"
echo "   - 添加设备: UDID = 00008120-001A10513622201E"
echo ""
echo "2. 【检查权限】确认账号状态:"
echo "   - 确认是付费开发者账号"
echo "   - 检查角色权限（需要Admin或App Manager）"
echo "   - 查看设备数量限制"
echo ""
echo "3. 【重新测试】手动注册后:"
echo "   - 重新运行 apple_id_password_flow.sh"
echo "   - 或者使用现有Profile直接签名"