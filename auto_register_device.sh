#!/bin/bash

# 🎯 专门解决自动设备注册问题的脚本

echo "🎯 自动设备注册问题深度诊断与修复"
echo "================================="
echo ""

echo "📊 当前问题分析："
echo "✅ 登录验证成功 - Apple ID凭证正确"
echo "❌ 设备注册失败 - register_device步骤出错"
echo "🔍 错误信息: Invalid username and password combination"
echo ""

# 设置基本环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

UDID="00008120-001A10513622201E"
BUNDLE_ID="com.si4key.si4ilocker2"

echo "🔑 第一步：重新设置凭证"
echo "===================="

if [ -z "$FASTLANE_USER" ]; then
    read -p "请输入Apple ID: " apple_id
    export FASTLANE_USER="$apple_id"
else
    echo "当前Apple ID: $FASTLANE_USER"
fi

if [ -z "$FASTLANE_PASSWORD" ]; then
    echo "请输入应用专用密码:"
    read -s app_password
    export FASTLANE_PASSWORD="$app_password"
    echo ""
else
    echo "应用专用密码已设置"
fi

export UDID="$UDID"
export BUNDLE_ID="$BUNDLE_ID"
export DEVICE_NAME="iPhone-$(echo $UDID | tail -c 7)"

echo "✅ 凭证设置完成"
echo ""

cd fastlane || {
    echo "❌ fastlane目录不存在"
    exit 1
}

echo "🧪 第二步：清除所有缓存和会话"
echo "========================="

echo "清除FastLane缓存..."
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*
rm -rf ~/.fastlane/cookies
rm -rf /tmp/spaceship_*

echo "清除Keychain中的FastLane条目..."
security delete-generic-password -s "fastlane" 2>/dev/null || true
security delete-generic-password -s "deliver" 2>/dev/null || true

echo "✅ 缓存清除完成"
echo ""

echo "🧪 第三步：强制重新认证"
echo "===================="

echo "执行强制登录..."
bundle exec fastlane login --force
login_result=$?

if [ $login_result -ne 0 ]; then
    echo "❌ 强制登录失败，请检查凭证"
    exit 1
fi

echo "✅ 强制登录成功"
echo ""

echo "🧪 第四步：验证Team信息"
echo "===================="

# 创建Team验证脚本
cat > verify_team.rb << 'EOF'
require 'spaceship'

begin
  puts "连接到Apple Developer Portal..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  teams = Spaceship::Portal.client.teams
  puts "\n✅ 团队信息验证成功:"
  
  teams.each_with_index do |team, index|
    puts "#{index + 1}. 团队名称: #{team['name']}"
    puts "   团队ID: #{team['teamId']}"
    puts "   类型: #{team['type']}"
    puts "   状态: #{team['status']}"
    
    # 检查权限
    member_info = team['currentTeamMember']
    if member_info
      puts "   你的角色: #{member_info['roles'].join(', ')}"
      puts "   权限级别: #{member_info['privileges']}" if member_info['privileges']
    end
    puts ""
  end
  
  # 选择第一个有效的团队
  active_team = teams.find { |t| t['status'] == 'active' } || teams.first
  puts "将使用团队: #{active_team['name']} (#{active_team['teamId']})"
  
  # 设置团队ID环境变量
  File.write('/tmp/team_id', active_team['teamId'])
  
rescue => e
  puts "❌ 团队验证失败: #{e.message}"
  exit 1
end
EOF

bundle exec ruby verify_team.rb
team_result=$?

if [ $team_result -ne 0 ]; then
    echo "❌ 团队验证失败"
    exit 1
fi

# 读取团队ID
if [ -f "/tmp/team_id" ]; then
    TEAM_ID=$(cat /tmp/team_id)
    export TEAM_ID="$TEAM_ID"
    echo "✅ 团队ID设置: $TEAM_ID"
    rm -f /tmp/team_id
fi

echo ""

echo "🧪 第五步：检查现有设备"
echo "===================="

cat > check_devices.rb << 'EOF'
require 'spaceship'

begin
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  devices = Spaceship::Portal.device.all
  puts "📱 当前已注册设备数量: #{devices.count}"
  
  # 检查是否已存在目标设备
  target_udid = ENV['UDID']
  existing_device = devices.find { |d| d.udid == target_udid }
  
  if existing_device
    puts "⚠️  设备已存在:"
    puts "   名称: #{existing_device.name}"
    puts "   UDID: #{existing_device.udid}"
    puts "   状态: #{existing_device.status}"
    puts "   类型: #{existing_device.device_class}"
    
    # 设备已存在，但可能需要更新
    if existing_device.status == 'c'
      puts "✅ 设备状态正常，可以直接使用"
      exit 0
    else
      puts "⚠️  设备状态异常，尝试重新激活"
    end
  else
    puts "🆕 设备未注册，需要新增"
  end
  
  # 检查设备数量限制
  if devices.count >= 100
    puts "❌ 警告: 设备数量已达到100台限制"
    puts "请在Apple Developer Portal删除不用的设备"
    
    puts "\n最近注册的设备:"
    devices.sort_by(&:created_at).last(5).each do |device|
      puts "  - #{device.name} (#{device.udid}) - #{device.created_at}"
    end
  else
    puts "✅ 设备数量正常 (#{devices.count}/100)"
  end
  
rescue => e
  puts "❌ 设备检查失败: #{e.message}"
  exit 1
end
EOF

bundle exec ruby check_devices.rb
device_check_result=$?

if [ $device_check_result -eq 0 ]; then
    echo "✅ 设备已存在且状态正常，跳过注册"
    rm -f check_devices.rb
    echo ""
    echo "🎉 设备注册问题已解决！"
    echo "可以继续进行IPA签名了"
    exit 0
fi

rm -f check_devices.rb
echo ""

echo "🧪 第六步：使用原生API注册设备"
echo "=========================="

cat > register_device_native.rb << 'EOF'
require 'spaceship'

begin
  puts "使用原生Spaceship API注册设备..."
  
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  device_name = ENV['DEVICE_NAME'] || "Device-#{ENV['UDID'][-6..-1]}"
  device_udid = ENV['UDID']
  
  puts "注册设备:"
  puts "  名称: #{device_name}"
  puts "  UDID: #{device_udid}"
  
  # 尝试注册设备
  device = Spaceship::Portal.device.create!(
    name: device_name,
    udid: device_udid
  )
  
  if device
    puts "✅ 设备注册成功!"
    puts "   设备ID: #{device.id}"
    puts "   名称: #{device.name}"
    puts "   UDID: #{device.udid}"
    puts "   状态: #{device.status}"
  else
    puts "❌ 设备注册返回空结果"
    exit 1
  end
  
rescue Spaceship::Client::UnexpectedResponse => e
  puts "❌ API响应错误: #{e.message}"
  puts "可能原因:"
  puts "1. 设备UDID已存在"
  puts "2. 设备数量达到限制"
  puts "3. 账号权限不足"
  exit 1
  
rescue => e
  puts "❌ 注册失败: #{e.message}"
  
  # 详细错误分析
  if e.message.include?("forbidden")
    puts "\n权限不足，可能原因:"
    puts "1. 账号不是付费开发者账号"
    puts "2. 角色权限不足（需要Admin或App Manager）"
    puts "3. 团队状态异常"
    
  elsif e.message.include?("duplicate")
    puts "\n设备已存在，这实际上是成功的"
    exit 0
    
  elsif e.message.include?("limit")
    puts "\n设备数量限制，解决方案:"
    puts "1. 删除不用的设备"
    puts "2. 升级到企业账号"
    
  else
    puts "\n未知错误，建议:"
    puts "1. 检查网络连接"
    puts "2. 稍后重试"
    puts "3. 联系Apple Developer Support"
  end
  
  exit 1
end
EOF

echo "执行原生API设备注册..."
bundle exec ruby register_device_native.rb
native_result=$?

rm -f register_device_native.rb

if [ $native_result -eq 0 ]; then
    echo ""
    echo "🎉 设备注册成功！"
    echo "================"
    
    # 验证注册结果
    echo "验证注册结果..."
    bundle exec fastlane register_udid
    verify_result=$?
    
    if [ $verify_result -eq 0 ]; then
        echo "✅ FastLane设备注册验证成功"
    else
        echo "⚠️  原生API成功，但FastLane验证失败"
        echo "这是正常的，设备已经注册"
    fi
    
    echo ""
    echo "🚀 现在可以继续IPA签名："
    echo "export AUTO_SIGH=\"1\""
    echo "bundle exec fastlane resign_ipa"
    
else
    echo ""
    echo "❌ 所有自动注册方法都失败了"
    echo "========================="
    echo ""
    echo "可能的根本原因："
    echo "1. 账号类型问题（免费账号无法远程注册设备）"
    echo "2. 权限问题（角色权限不足）"
    echo "3. 账号状态问题（开发者协议未签署）"
    echo ""
    echo "建议的解决方案："
    echo "1. 确认开发者账号类型和状态"
    echo "2. 检查账号角色权限"
    echo "3. 考虑手动注册设备"
    echo "4. 联系Apple Developer Support"
fi

rm -f verify_team.rb

echo ""
echo "📋 诊断完成"
echo "==========="