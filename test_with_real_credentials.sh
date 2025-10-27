#!/bin/bash

# 🎯 使用完整凭证进行设备注册测试

echo "🔧 完整凭证设备注册测试"
echo "======================"
echo ""

echo "📋 凭证信息确认:"
echo "Apple ID: copybytes@163.com"
echo "Team ID: X855Y85A4V"
echo "应用专用密码: avcf-ufri-tcvs-ibet"
echo "设备UDID: 00008120-001A10513622201E"
echo ""

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

export FASTLANE_USER="copybytes@163.com"
export FASTLANE_PASSWORD="mmjh-upex-rswk-yfnb"
export TEAM_ID="X855Y85A4V"
export UDID="00008120-001A10513622201E"
export BUNDLE_ID="exam.duo.apih"
export DEVICE_NAME="iPhone-22201E"

echo "🧹 清除缓存"
echo "==========="
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*
rm -rf ~/.fastlane/cookies
rm -rf /tmp/spaceship_*
security delete-generic-password -s "fastlane" 2>/dev/null || true

cd fastlane

echo ""
echo "🧪 第一步：验证登录和团队信息"
echo "=========================="

cat > detailed_auth_test.rb << 'EOF'
require 'spaceship'

begin
  puts "🔐 登录测试..."
  puts "用户: #{ENV['FASTLANE_USER']}"
  puts "Team ID: #{ENV['TEAM_ID']}"
  puts ""
  
  # 登录
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 登录成功"
  
  # 获取团队信息
  teams = Spaceship::Portal.client.teams
  puts "\n📊 团队信息:"
  
  target_team = nil
  teams.each do |team|
    is_target = team['teamId'] == ENV['TEAM_ID']
    marker = is_target ? "👉 " : "   "
    
    puts "#{marker}团队: #{team['name']}"
    puts "#{marker}ID: #{team['teamId']}"
    puts "#{marker}类型: #{team['type']}"
    puts "#{marker}状态: #{team['status']}"
    
    if team['currentTeamMember']
      member = team['currentTeamMember']
      puts "#{marker}角色: #{member['roles'].join(', ')}"
      puts "#{marker}权限: #{member['privileges']}" if member['privileges']
    end
    puts ""
    
    target_team = team if is_target
  end
  
  if target_team
    puts "✅ 找到目标团队: #{target_team['name']}"
    
    # 检查权限
    member = target_team['currentTeamMember']
    if member && member['roles']
      roles = member['roles']
      if roles.include?('ADMIN') || roles.include?('APP_MANAGER')
        puts "✅ 权限足够: #{roles.join(', ')}"
      else
        puts "❌ 权限不足: #{roles.join(', ')}"
        puts "需要: ADMIN 或 APP_MANAGER"
        puts "这可能是设备注册失败的原因！"
      end
    end
  else
    puts "❌ 未找到指定的Team ID: #{ENV['TEAM_ID']}"
    puts "请检查Team ID是否正确"
    exit 1
  end
  
rescue => e
  puts "❌ 登录失败: #{e.message}"
  puts "错误类型: #{e.class}"
  exit 1
end
EOF

bundle exec ruby detailed_auth_test.rb
auth_result=$?

rm -f detailed_auth_test.rb

if [ $auth_result -ne 0 ]; then
    echo "❌ 认证测试失败，无法继续"
    exit 1
fi

echo ""
echo "🧪 第二步：检查现有设备"
echo "==================="

cat > check_existing_devices.rb << 'EOF'
require 'spaceship'

begin
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  # 选择正确的团队
  teams = Spaceship::Portal.client.teams
  target_team = teams.find { |t| t['teamId'] == ENV['TEAM_ID'] }
  
  if target_team
    puts "使用团队: #{target_team['name']} (#{target_team['teamId']})"
  else
    puts "❌ 未找到团队"
    exit 1
  end
  
  # 获取设备列表
  devices = Spaceship::Portal.device.all
  puts "\n📱 设备统计:"
  puts "总设备数: #{devices.count}"
  
  # 按平台分类
  device_counts = devices.group_by(&:platform).map { |platform, devs| [platform, devs.count] }.to_h
  device_counts.each do |platform, count|
    puts "#{platform}: #{count}台"
  end
  
  # 检查目标设备
  target_udid = ENV['UDID']
  existing_device = devices.find { |d| d.udid == target_udid }
  
  if existing_device
    puts "\n⚠️  设备已存在:"
    puts "名称: #{existing_device.name}"
    puts "UDID: #{existing_device.udid}"
    puts "平台: #{existing_device.platform}"
    puts "状态: #{existing_device.status}"
    puts "设备类: #{existing_device.device_class}"
    puts "创建时间: #{existing_device.created_at}"
    
    if existing_device.status == 'c'
      puts "✅ 设备状态正常"
      puts "设备已注册，可以直接使用"
      exit 0
    else
      puts "⚠️  设备状态异常: #{existing_device.status}"
    end
  else
    puts "\n🆕 设备未注册"
    puts "UDID: #{target_udid}"
    puts "需要注册新设备"
  end
  
  # 检查设备限制
  ios_devices = devices.select { |d| d.platform == 'ios' }
  puts "\niOS设备数量: #{ios_devices.count}/100"
  
  if ios_devices.count >= 100
    puts "❌ iOS设备数量已达到限制"
    puts "需要删除不用的设备才能注册新设备"
    
    puts "\n最近注册的iOS设备:"
    ios_devices.sort_by(&:created_at).last(5).each do |device|
      puts "  #{device.name} (#{device.udid[-8..-1]}) - #{device.created_at}"
    end
  else
    puts "✅ iOS设备数量正常，可以注册新设备"
  end
  
rescue => e
  puts "❌ 设备检查失败: #{e.message}"
  exit 1
end
EOF

bundle exec ruby check_existing_devices.rb
device_check_result=$?

rm -f check_existing_devices.rb

if [ $device_check_result -eq 0 ]; then
    echo ""
    echo "✅ 设备已存在且可用，无需重新注册"
    echo "可以直接进行IPA签名"
    exit 0
fi

echo ""
echo "🧪 第三步：尝试注册设备"
echo "==================="

cat > register_device_test.rb << 'EOF'
require 'spaceship'

begin
  puts "🔐 重新登录..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  device_name = ENV['DEVICE_NAME']
  device_udid = ENV['UDID']
  
  puts "注册设备:"
  puts "名称: #{device_name}"
  puts "UDID: #{device_udid}"
  puts ""
  
  # 尝试注册
  puts "执行注册..."
  device = Spaceship::Portal.device.create!(
    name: device_name,
    udid: device_udid
  )
  
  if device
    puts "✅ 设备注册成功!"
    puts "设备ID: #{device.id}"
    puts "名称: #{device.name}"
    puts "UDID: #{device.udid}"
    puts "平台: #{device.platform}"
    puts "状态: #{device.status}"
  else
    puts "❌ 注册返回空结果"
    exit 1
  end
  
rescue Spaceship::Client::UnexpectedResponse => e
  puts "❌ API响应错误"
  puts "错误信息: #{e.message}"
  puts "HTTP状态: #{e.status_code}" if e.respond_to?(:status_code)
  
  if e.message.include?("duplicate") || e.message.include?("already exists")
    puts "\n实际上这表示设备已存在，这是正常的"
    puts "✅ 设备注册状态: 已存在"
    exit 0
  elsif e.message.include?("forbidden") || e.message.include?("not authorized")
    puts "\n权限问题分析:"
    puts "1. 账号角色权限不足"
    puts "2. 团队状态异常"
    puts "3. 开发者协议未签署"
    exit 1
  elsif e.message.include?("limit") || e.message.include?("maximum")
    puts "\n设备数量限制问题:"
    puts "1. 已达到100台设备限制"
    puts "2. 需要删除不用的设备"
    exit 1
  else
    puts "\n未知API错误"
    puts "建议联系Apple Developer Support"
    exit 1
  end
  
rescue => e
  puts "❌ 注册失败: #{e.message}"
  puts "错误类型: #{e.class}"
  
  if e.message.include?("Invalid username and password")
    puts "\n认证问题:"
    puts "1. 应用专用密码可能已过期"
    puts "2. 重新生成应用专用密码"
  elsif e.message.include?("forbidden")
    puts "\n权限问题:"
    puts "1. 账号角色权限不足"
    puts "2. 需要Admin或App Manager权限"
  else
    puts "\n其他问题:"
    puts "1. 网络连接问题"
    puts "2. Apple服务器暂时不可用"
    puts "3. 稍后重试"
  end
  
  exit 1
end
EOF

echo "执行设备注册测试..."
bundle exec ruby register_device_test.rb
register_result=$?

rm -f register_device_test.rb

if [ $register_result -eq 0 ]; then
    echo ""
    echo "🎉 设备注册成功!"
    echo "==============="
    
    echo ""
    echo "🧪 验证FastLane注册"
    echo "=================="
    echo "现在测试FastLane的register_udid是否也能成功..."
    
    bundle exec fastlane register_udid
    fastlane_result=$?
    
    if [ $fastlane_result -eq 0 ]; then
        echo "✅ FastLane注册验证成功"
    else
        echo "⚠️  原生API成功，但FastLane失败"
        echo "这通常是正常的，设备已经注册了"
    fi
    
    echo ""
    echo "🚀 现在可以继续IPA签名:"
    echo "======================"
    echo "export AUTO_SIGH=\"1\""
    echo "export IPA_PATH=\"/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa\""
    echo "export SIGN_IDENTITY=\"72932C2C26F5B806F2D2536BD2B3658F1C3C842C\""
    echo "bundle exec fastlane resign_ipa"
    
else
    echo ""
    echo "❌ 设备注册失败"
    echo "=============="
    echo ""
    echo "基于你的凭证信息分析:"
    echo "Apple ID: copybytes@163.com"
    echo "Team ID: X855Y85A4V"
    echo "应用专用密码: mmjh-upex-rswk-yfnb"
    echo ""
    echo "可能的原因:"
    echo "1. 账号角色权限不足（需要Admin或App Manager）"
    echo "2. iOS设备数量已达到100台限制"
    echo "3. Apple Developer Portal服务问题"
    echo ""
    echo "建议解决方案:"
    echo "1. 在Apple Developer Portal手动注册设备"
    echo "2. 检查账号权限和设备数量"
    echo "3. 联系Apple Developer Support"
fi

echo ""
echo "📋 完整的环境变量配置:"
echo "====================="
echo "export FASTLANE_USER=\"copybytes@163.com\""
echo "export FASTLANE_PASSWORD=\"mmjh-upex-rswk-yfnb\""
echo "export TEAM_ID=\"X855Y85A4V\""
echo "export UDID=\"00008120-001A10513622201E\""
echo "export BUNDLE_ID=\"exam.duo.apih\""
echo "export DEVICE_NAME=\"iPhone-22201E\""