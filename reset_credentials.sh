#!/bin/bash

echo "🔐 重新设置Apple ID凭证"
echo "====================="
echo ""

echo "⚠️  重要提醒："
echo "1. 必须使用应用专用密码，不能使用Apple ID主密码"
echo "2. 应用专用密码格式：xxxx-xxxx-xxxx-xxxx"
echo "3. 如果没有，请访问 https://appleid.apple.com 生成"
echo ""

# 清除所有可能的缓存
echo "清除所有FastLane缓存..."
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*
rm -rf ~/.fastlane/cookies
rm -rf /tmp/spaceship_*
security delete-generic-password -s "fastlane" 2>/dev/null || true

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

echo ""
echo "请输入你的Apple ID:"
read apple_id

echo ""
echo "请输入应用专用密码（格式：xxxx-xxxx-xxxx-xxxx）:"
echo "注意：这不是你的Apple ID主密码！"
read -s app_password
echo ""

# 验证密码格式
if [[ ! $app_password =~ ^[a-z]{4}-[a-z]{4}-[a-z]{4}-[a-z]{4}$ ]]; then
    echo "⚠️  警告：应用专用密码格式可能不正确"
    echo "正确格式应该是：xxxx-xxxx-xxxx-xxxx (小写字母)"
    echo ""
    read -p "是否继续？(y/n): " continue_anyway
    if [ "$continue_anyway" != "y" ]; then
        exit 1
    fi
fi

export FASTLANE_USER="$apple_id"
export FASTLANE_PASSWORD="$app_password"

echo "✅ 凭证设置完成"
echo ""

cd fastlane

echo "🧪 测试基本登录"
echo "=============="

# 创建最简单的登录测试
cat > simple_login_test.rb << 'EOF'
require 'spaceship'

begin
  puts "测试登录到Apple Developer Portal..."
  puts "用户: #{ENV['FASTLANE_USER']}"
  
  # 尝试登录
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  puts "✅ 登录成功！"
  
  # 获取基本信息
  teams = Spaceship::Portal.client.teams
  puts "\n📊 账号信息:"
  puts "可用团队数量: #{teams.count}"
  
  teams.each_with_index do |team, index|
    puts "\n团队 #{index + 1}:"
    puts "  名称: #{team['name']}"
    puts "  ID: #{team['teamId']}"
    puts "  类型: #{team['type']}"
    puts "  状态: #{team['status']}"
    
    member = team['currentTeamMember']
    if member
      puts "  你的角色: #{member['roles'].join(', ')}"
      
      # 检查设备管理权限
      roles = member['roles']
      if roles.include?('ADMIN') || roles.include?('APP_MANAGER')
        puts "  ✅ 有设备管理权限"
      else
        puts "  ❌ 设备管理权限不足"
        puts "     需要: ADMIN 或 APP_MANAGER"
        puts "     当前: #{roles.join(', ')}"
      end
    end
  end
  
  # 选择活跃团队
  active_team = teams.find { |t| t['status'] == 'active' } || teams.first
  if active_team
    puts "\n✅ 将使用团队: #{active_team['name']} (#{active_team['teamId']})"
    File.write('/tmp/team_id_success', active_team['teamId'])
  end
  
rescue Spaceship::Client::InvalidUserCredentialsError => e
  puts "❌ 凭证错误: #{e.message}"
  puts ""
  puts "可能的问题："
  puts "1. 使用了Apple ID主密码而不是应用专用密码"
  puts "2. 应用专用密码格式错误"
  puts "3. 应用专用密码已过期"
  puts ""
  puts "解决方案："
  puts "1. 访问 https://appleid.apple.com"
  puts "2. 进入「登录和安全」"
  puts "3. 重新生成「应用专用密码」"
  puts "4. 使用新生成的密码重试"
  exit 1
  
rescue => e
  puts "❌ 登录失败: #{e.message}"
  puts ""
  puts "错误类型: #{e.class}"
  puts ""
  if e.message.include?("Invalid username and password")
    puts "这是凭证问题，请检查："
    puts "1. Apple ID是否正确"
    puts "2. 是否使用应用专用密码"
    puts "3. 密码是否输入正确"
  elsif e.message.include?("forbidden")
    puts "这是权限问题，请检查："
    puts "1. 账号是否是付费开发者账号"
    puts "2. 开发者协议是否已签署"
  else
    puts "未知错误，建议："
    puts "1. 检查网络连接"
    puts "2. 稍后重试"
    puts "3. 联系Apple Developer Support"
  end
  exit 1
end
EOF

echo "执行登录测试..."
bundle exec ruby simple_login_test.rb
login_result=$?

rm -f simple_login_test.rb

if [ $login_result -eq 0 ]; then
    if [ -f "/tmp/team_id_success" ]; then
        TEAM_ID=$(cat /tmp/team_id_success)
        export TEAM_ID="$TEAM_ID"
        rm -f /tmp/team_id_success
        
        echo ""
        echo "🎉 登录成功！开始设备注册测试"
        echo "============================"
        echo ""
        
        export UDID="00008120-001A10513622201E"
        export BUNDLE_ID="exam.duo.apih"
        export DEVICE_NAME="iPhone-$(echo $UDID | tail -c 7)"
        
        echo "设备注册参数："
        echo "TEAM_ID: $TEAM_ID"
        echo "UDID: $UDID"
        echo "BUNDLE_ID: $BUNDLE_ID"
        echo "DEVICE_NAME: $DEVICE_NAME"
        echo ""
        
        echo "执行设备注册..."
        bundle exec fastlane register_udid
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "🎉 设备注册成功！"
            echo "================"
            echo ""
            echo "现在可以继续IPA签名了"
            echo ""
            echo "完整的环境变量配置："
            echo "export FASTLANE_USER=\"$apple_id\""
            echo "export FASTLANE_PASSWORD=\"[你的应用专用密码]\""
            echo "export TEAM_ID=\"$TEAM_ID\""
            echo "export UDID=\"$UDID\""
            echo "export BUNDLE_ID=\"$BUNDLE_ID\""
            echo "export DEVICE_NAME=\"$DEVICE_NAME\""
        else
            echo ""
            echo "❌ 设备注册失败"
            echo "可能原因："
            echo "1. 设备数量达到限制"
            echo "2. UDID已存在"
            echo "3. 权限不足"
        fi
    fi
else
    echo ""
    echo "❌ 登录测试失败"
    echo "请检查凭证并重试"
fi