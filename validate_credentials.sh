#!/bin/bash

echo "🔍 应用专用密码验证工具"
echo "===================="
echo ""

echo "📋 当前信息:"
echo "Apple ID: copybytes@163.com"
echo "Team ID: X855Y85A4V"
echo "应用专用密码: mmjh-upex-rswk-yfnb"
echo ""

echo "🔍 密码格式检查:"
password="mmjh-upex-rswk-yfnb"

# 检查密码格式
if [[ $password =~ ^[a-z]{4}-[a-z]{4}-[a-z]{4}-[a-z]{4}$ ]]; then
    echo "✅ 密码格式正确"
else
    echo "❌ 密码格式可能有问题"
    echo "正确格式应该是: xxxx-xxxx-xxxx-xxxx (小写字母)"
fi

echo ""
echo "🧪 基础连接测试"
echo "=============="

export FASTLANE_USER="copybytes@163.com"
export FASTLANE_PASSWORD="mmjh-upex-rswk-yfnb"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# 清除所有缓存
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*

cd fastlane

# 创建最简单的验证脚本
cat > simple_auth_test.rb << 'EOF'
require 'spaceship'

puts "测试连接到Apple Developer Portal..."
puts "Apple ID: #{ENV['FASTLANE_USER']}"
puts "密码长度: #{ENV['FASTLANE_PASSWORD'].length}字符"
puts ""

begin
  # 尝试最基本的登录
  puts "执行登录..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  
  puts "✅ 登录成功!"
  puts ""
  
  # 获取用户信息
  user_info = Spaceship::Portal.client.user_details
  puts "👤 用户信息:"
  puts "名称: #{user_info['firstName']} #{user_info['lastName']}"
  puts "Apple ID: #{user_info['userName']}"
  puts ""
  
  # 获取团队信息
  teams = Spaceship::Portal.client.teams
  puts "🏢 团队信息:"
  puts "团队数量: #{teams.count}"
  
  teams.each_with_index do |team, index|
    puts "\n团队 #{index + 1}:"
    puts "  名称: #{team['name']}"
    puts "  ID: #{team['teamId']}"
    puts "  类型: #{team['type']}"
    puts "  状态: #{team['status']}"
    
    member = team['currentTeamMember']
    if member
      puts "  角色: #{member['roles'].join(', ')}"
    end
  end
  
rescue Spaceship::Client::InvalidUserCredentialsError => e
  puts "❌ 凭证错误"
  puts "错误: #{e.message}"
  puts ""
  puts "可能的问题:"
  puts "1. 应用专用密码错误或已过期"
  puts "2. Apple ID输入错误"
  puts "3. 账号被锁定或暂停"
  puts ""
  puts "建议解决方案:"
  puts "1. 重新生成应用专用密码"
  puts "2. 确认Apple ID拼写正确"
  puts "3. 检查账号状态"
  
rescue Spaceship::Client::UnexpectedResponse => e
  puts "❌ 服务器响应错误"
  puts "错误: #{e.message}"
  puts "状态码: #{e.status_code}" if e.respond_to?(:status_code)
  puts ""
  puts "可能的问题:"
  puts "1. Apple服务器临时问题"
  puts "2. 网络连接问题"
  puts "3. 账号需要额外验证"
  
rescue => e
  puts "❌ 未知错误"
  puts "错误类型: #{e.class}"
  puts "错误信息: #{e.message}"
  puts ""
  puts "建议:"
  puts "1. 检查网络连接"
  puts "2. 稍后重试"
  puts "3. 更新fastlane版本"
end
EOF

echo "执行基础认证测试..."
bundle exec ruby simple_auth_test.rb

rm -f simple_auth_test.rb

echo ""
echo "🔧 问题诊断和解决建议"
echo "=================="
echo ""
echo "如果上面的测试失败，请按以下步骤检查:"
echo ""
echo "1. 验证应用专用密码:"
echo "   - 访问 https://appleid.apple.com"
echo "   - 登录 copybytes@163.com"
echo "   - 检查「应用专用密码」部分"
echo "   - 确认 mmjh-upex-rswk-yfnb 是否有效"
echo "   - 如有疑问，重新生成新的密码"
echo ""
echo "2. 检查账号状态:"
echo "   - 访问 https://developer.apple.com"
echo "   - 确认开发者账号是否有效"
echo "   - 检查是否有待签署的协议"
echo ""
echo "3. 确认Team ID:"
echo "   - 在Apple Developer Portal确认"
echo "   - Team ID: X855Y85A4V"
echo "   - 确认你在该团队中的角色"
echo ""
echo "4. 网络检查:"
echo "   - 确认能访问 developer.apple.com"
echo "   - 检查是否需要VPN"
echo "   - 尝试不同的网络环境"
echo ""
echo "如果问题持续存在，建议:"
echo "- 重新生成应用专用密码"
echo "- 联系Apple Developer Support"
echo "- 尝试使用其他开发者账号测试"