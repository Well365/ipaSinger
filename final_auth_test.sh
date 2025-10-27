#!/bin/bash

echo "🔍 最终认证测试"
echo "==============="

# 设置环境变量
export FASTLANE_USER="copybytes@163.com"
echo "请再次输入应用专用密码："
read -s password
export FASTLANE_PASSWORD="$password"

echo ""
echo "密码: $password"
echo "长度: ${#password}"

cd fastlane

echo ""
echo "🧪 最终测试：能否实际进行设备注册"
echo "=========================="

# 清除缓存
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*

# 测试实际的设备注册
cat > final_test.rb << 'EOF'
require 'spaceship'

begin
  puts "开始最终测试..."
  
  # 尝试登录
  puts "1. 尝试登录..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 登录成功"
  
  # 获取团队信息
  puts "2. 获取团队信息..."
  teams = Spaceship::Portal.client.teams
  puts "找到 #{teams.length} 个团队"
  teams.each { |team| puts "   - #{team['name']} (#{team['teamId']})" }
  
  # 选择团队
  puts "3. 选择团队..."
  target_team = teams.find { |team| team['teamId'] == 'X855Y85A4V' }
  if target_team
    Spaceship::Portal.client.team_id = target_team['teamId']
    puts "✅ 团队选择成功: #{target_team['name']}"
  else
    puts "❌ 未找到团队 X855Y85A4V"
    puts "可用团队:"
    teams.each { |team| puts "   - #{team['teamId']}: #{team['name']}" }
    exit 1
  end
  
  # 尝试获取设备列表
  puts "4. 获取设备列表..."
  devices = Spaceship::Portal.device.all
  puts "✅ 当前注册设备: #{devices.length} 个"
  
  # 检查目标设备是否已存在
  target_udid = "00008120-001A10513622201E"
  existing_device = devices.find { |device| device.udid == target_udid }
  
  if existing_device
    puts "✅ 设备已存在: #{existing_device.name} (#{existing_device.udid})"
  else
    puts "ℹ️  设备不存在，可以注册"
    puts "   UDID: #{target_udid}"
  end
  
  puts ""
  puts "🎉 所有测试通过！认证和API访问都正常工作"
  exit 0
  
rescue => e
  puts "❌ 测试失败: #{e.message}"
  puts "错误类型: #{e.class}"
  puts "详细信息: #{e.backtrace.first(3).join('\n')}" if e.backtrace
  exit 1
end
EOF

echo "运行最终测试..."
bundle exec ruby final_test.rb
result=$?

rm -f final_test.rb

if [ $result -eq 0 ]; then
    echo ""
    echo "🎉 认证成功！现在可以注册设备了"
    echo ""
    echo "执行设备注册："
    echo "bundle exec fastlane register_udid"
    echo ""
    echo "或者运行完整流程："
    echo "bundle exec fastlane resign_ipa"
else
    echo ""
    echo "❌ 认证仍然失败"
    echo ""
    echo "可能的问题："
    echo "1. 应用专用密码仍然无效"
    echo "2. 账号权限问题"
    echo "3. Apple服务器问题"
    echo ""
    echo "建议："
    echo "1. 再次生成新的应用专用密码"
    echo "2. 等待几分钟后重试"
    echo "3. 联系Apple Developer Support"
fi