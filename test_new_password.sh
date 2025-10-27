#!/bin/bash

echo "🔄 新应用专用密码测试"
echo "=================="
echo ""

echo "请输入新生成的应用专用密码:"
read -s new_password
echo ""

if [ -z "$new_password" ]; then
    echo "❌ 密码不能为空"
    exit 1
fi

# 验证格式
if [[ ! $new_password =~ ^[a-z]{4}-[a-z]{4}-[a-z]{4}-[a-z]{4}$ ]]; then
    echo "⚠️  密码格式警告"
    echo "期望格式: xxxx-xxxx-xxxx-xxxx"
    echo "当前格式: $new_password"
    echo ""
    read -p "是否继续测试？(y/n): " continue_test
    if [ "$continue_test" != "y" ]; then
        exit 1
    fi
fi

export FASTLANE_USER="copybytes@163.com"
export FASTLANE_PASSWORD="$new_password"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# 清除缓存
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*

cd fastlane

echo "🧪 测试新密码..."
echo ""

cat > test_new_password.rb << 'EOF'
require 'spaceship'

begin
  puts "使用新密码登录..."
  puts "Apple ID: #{ENV['FASTLANE_USER']}"
  puts ""
  
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  puts "🎉 新密码验证成功!"
  puts ""
  
  # 获取团队信息
  teams = Spaceship::Portal.client.teams
  target_team = teams.find { |t| t['teamId'] == 'X855Y85A4V' }
  
  if target_team
    puts "✅ 找到目标团队:"
    puts "名称: #{target_team['name']}"
    puts "ID: #{target_team['teamId']}"
    puts "状态: #{target_team['status']}"
    
    member = target_team['currentTeamMember']
    if member
      roles = member['roles']
      puts "角色: #{roles.join(', ')}"
      
      if roles.include?('ADMIN') || roles.include?('APP_MANAGER')
        puts "✅ 权限足够，可以注册设备"
      else
        puts "⚠️  权限可能不足: #{roles.join(', ')}"
      end
    end
  else
    puts "❌ 未找到Team ID: X855Y85A4V"
  end
  
  # 保存成功的密码
  File.write('/tmp/working_password', ENV['FASTLANE_PASSWORD'])
  
rescue => e
  puts "❌ 新密码测试失败: #{e.message}"
  exit 1
end
EOF

bundle exec ruby test_new_password.rb
test_result=$?

rm -f test_new_password.rb

if [ $test_result -eq 0 ]; then
    if [ -f "/tmp/working_password" ]; then
        working_password=$(cat /tmp/working_password)
        rm -f /tmp/working_password
        
        echo ""
        echo "🎉 新密码工作正常！"
        echo "================="
        echo ""
        echo "现在尝试设备注册..."
        
        export TEAM_ID="X855Y85A4V"
        export UDID="00008120-001A10513622201E"
        export BUNDLE_ID="exam.duo.apih"
        export DEVICE_NAME="iPhone-22201E"
        
        echo "设备注册参数:"
        echo "Team ID: $TEAM_ID"
        echo "UDID: $UDID"
        echo "Bundle ID: $BUNDLE_ID"
        echo "Device Name: $DEVICE_NAME"
        echo ""
        
        bundle exec fastlane register_udid
        register_result=$?
        
        if [ $register_result -eq 0 ]; then
            echo ""
            echo "🎉 设备注册成功！"
            echo "================"
            echo ""
            echo "保存成功的配置:"
            echo "export FASTLANE_USER=\"copybytes@163.com\""
            echo "export FASTLANE_PASSWORD=\"$working_password\""
            echo "export TEAM_ID=\"X855Y85A4V\""
            echo "export UDID=\"00008120-001A10513622201E\""
            echo "export BUNDLE_ID=\"exam.duo.apih\""
            echo "export DEVICE_NAME=\"iPhone-22201E\""
            echo ""
            echo "现在可以继续IPA签名了!"
        else
            echo ""
            echo "⚠️  登录成功但设备注册失败"
            echo "这可能是权限或设备数量限制问题"
        fi
    fi
else
    echo ""
    echo "❌ 新密码测试失败"
    echo "请重新生成应用专用密码"
fi