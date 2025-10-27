#!/bin/bash

# 🎯 解决Team ID和设备注册问题

echo "🔧 修复自动设备注册 - Team ID问题"
echo "==============================="
echo ""

echo "🔍 问题分析："
echo "Fastfile中的register_device需要TEAM_ID，但未设置"
echo "导致在team验证时重新触发登录认证失败"
echo ""

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

UDID="00008120-001A10513622201E"
BUNDLE_ID="exam.duo.apih"

echo "🔑 设置凭证"
echo "=========="

if [ -z "$FASTLANE_USER" ]; then
    read -p "请输入Apple ID: " apple_id
    export FASTLANE_USER="$apple_id"
else
    echo "Apple ID: $FASTLANE_USER"
fi

if [ -z "$FASTLANE_PASSWORD" ]; then
    echo "请输入应用专用密码:"
    read -s app_password
    export FASTLANE_PASSWORD="$app_password"
    echo ""
fi

export UDID="$UDID"
export BUNDLE_ID="$BUNDLE_ID"
export DEVICE_NAME="iPhone-$(echo $UDID | tail -c 7)"

cd fastlane

echo "🔍 第一步：获取Team ID"
echo "==================="

# 创建获取Team ID的脚本
cat > get_team_id.rb << 'EOF'
require 'spaceship'

begin
  puts "登录Apple Developer Portal..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 登录成功"
  
  teams = Spaceship::Portal.client.teams
  puts "\n📊 可用团队:"
  
  teams.each_with_index do |team, index|
    puts "#{index + 1}. #{team['name']} (#{team['teamId']})"
    puts "   类型: #{team['type']}"
    puts "   状态: #{team['status']}"
    puts "   你的角色: #{team['currentTeamMember']['roles'].join(', ')}" if team['currentTeamMember']
    puts ""
  end
  
  # 找到第一个活跃的团队
  active_team = teams.find { |t| t['status'] == 'active' } || teams.first
  
  if active_team
    puts "选择团队: #{active_team['name']}"
    puts "Team ID: #{active_team['teamId']}"
    
    # 保存Team ID
    File.write('/tmp/fastlane_team_id', active_team['teamId'])
    
    # 检查权限
    member = active_team['currentTeamMember']
    if member && member['roles']
      roles = member['roles']
      if roles.include?('ADMIN') || roles.include?('APP_MANAGER')
        puts "✅ 权限足够: #{roles.join(', ')}"
      else
        puts "⚠️  权限可能不足: #{roles.join(', ')}"
        puts "建议权限: ADMIN 或 APP_MANAGER"
      end
    end
  else
    puts "❌ 未找到可用团队"
    exit 1
  end
  
rescue => e
  puts "❌ 获取Team ID失败: #{e.message}"
  exit 1
end
EOF

bundle exec ruby get_team_id.rb
team_result=$?

if [ $team_result -ne 0 ]; then
    echo "❌ 获取Team ID失败"
    rm -f get_team_id.rb
    exit 1
fi

if [ -f "/tmp/fastlane_team_id" ]; then
    TEAM_ID=$(cat /tmp/fastlane_team_id)
    export TEAM_ID="$TEAM_ID"
    echo "✅ Team ID设置: $TEAM_ID"
    rm -f /tmp/fastlane_team_id
else
    echo "❌ 未能获取Team ID"
    rm -f get_team_id.rb
    exit 1
fi

rm -f get_team_id.rb
echo ""

echo "🧪 第二步：验证完整环境"
echo "===================="

echo "环境变量检查:"
echo "FASTLANE_USER: $FASTLANE_USER"
echo "FASTLANE_PASSWORD: [已设置]"
echo "TEAM_ID: $TEAM_ID"
echo "UDID: $UDID"
echo "BUNDLE_ID: $BUNDLE_ID"
echo "DEVICE_NAME: $DEVICE_NAME"
echo ""

echo "🚀 第三步：执行设备注册"
echo "===================="

echo "清除可能的session冲突..."
rm -rf ~/.fastlane/spaceship_*

echo ""
echo "执行 register_udid..."
bundle exec fastlane register_udid

register_result=$?

if [ $register_result -eq 0 ]; then
    echo ""
    echo "🎉 设备注册成功！"
    echo "================"
    
    echo "✅ 验证设备注册结果..."
    
    # 验证设备确实注册了
    cat > verify_registration.rb << 'EOF'
require 'spaceship'

begin
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  devices = Spaceship::Portal.device.all
  target_device = devices.find { |d| d.udid == ENV['UDID'] }
  
  if target_device
    puts "✅ 设备验证成功:"
    puts "   名称: #{target_device.name}"
    puts "   UDID: #{target_device.udid}"
    puts "   状态: #{target_device.status}"
    puts "   创建时间: #{target_device.created_at}"
  else
    puts "❌ 设备未找到"
    exit 1
  end
  
rescue => e
  puts "❌ 验证失败: #{e.message}"
  exit 1
end
EOF

    bundle exec ruby verify_registration.rb
    verify_result=$?
    rm -f verify_registration.rb
    
    if [ $verify_result -eq 0 ]; then
        echo ""
        echo "🚀 现在可以继续IPA签名："
        echo "========================"
        echo ""
        echo "所有环境变量已设置完成，执行签名："
        echo "export AUTO_SIGH=\"1\""
        echo "export IPA_PATH=\"/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa\""
        echo "export SIGN_IDENTITY=\"72932C2C26F5B806F2D2536BD2B3658F1C3C842C\""
        echo "bundle exec fastlane resign_ipa"
        echo ""
        
        read -p "是否立即执行IPA重签名？(y/n): " do_resign
        
        if [ "$do_resign" = "y" ]; then
            export AUTO_SIGH="1"
            export IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
            export SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"
            
            echo ""
            echo "🚀 执行IPA重签名..."
            bundle exec fastlane resign_ipa
            
            if [ $? -eq 0 ]; then
                echo ""
                echo "🎉 完整流程成功！"
                echo "================"
                echo "✅ 设备自动注册成功"
                echo "✅ IPA重新签名成功"
                echo ""
                echo "输出文件位置: ./out/"
                ls -la ./out/ 2>/dev/null || echo "检查输出目录..."
            fi
        fi
    fi
    
else
    echo ""
    echo "❌ 设备注册仍然失败"
    echo "=================="
    
    echo ""
    echo "详细错误分析和解决方案："
    echo ""
    echo "1. 检查账号类型："
    echo "   - 访问 https://developer.apple.com"
    echo "   - 确认是付费开发者账号"
    echo "   - 免费账号无法远程注册设备"
    echo ""
    echo "2. 检查角色权限："
    echo "   - 需要 Admin 或 App Manager 角色"
    echo "   - Developer 角色权限不足"
    echo ""
    echo "3. 检查设备数量："
    echo "   - 个人账号限制100台设备"
    echo "   - 企业账号无限制"
    echo ""
    echo "4. 检查网络和服务："
    echo "   - Apple Developer Portal 服务状态"
    echo "   - 网络连接稳定性"
    echo ""
    echo "建议："
    echo "- 手动在Apple Developer Portal注册设备"
    echo "- 或联系Apple Developer Support"
fi

echo ""
echo "📋 环境配置保存"
echo "=============="
echo ""
echo "成功的环境变量配置："
echo "export FASTLANE_USER=\"$FASTLANE_USER\""
echo "export FASTLANE_PASSWORD=\"[你的应用专用密码]\""
echo "export TEAM_ID=\"$TEAM_ID\""
echo "export UDID=\"$UDID\""
echo "export BUNDLE_ID=\"$BUNDLE_ID\""
echo "export DEVICE_NAME=\"$DEVICE_NAME\""