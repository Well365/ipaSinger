#!/bin/bash

echo "🔍 深度诊断：应用专用密码问题"
echo "=========================="
echo ""

echo "⚠️  即使是新生成的应用专用密码也无法工作"
echo "这通常表示更深层的问题..."
echo ""

echo "🔍 第一步：确认账号基本信息"
echo "======================"

echo "请确认以下信息是否完全正确："
echo "Apple ID: copybytes@163.com"
read -p "Apple ID是否正确？(y/n): " apple_id_correct

if [ "$apple_id_correct" != "y" ]; then
    read -p "请输入正确的Apple ID: " correct_apple_id
    export FASTLANE_USER="$correct_apple_id"
else
    export FASTLANE_USER="copybytes@163.com"
fi

echo ""
echo "🔍 第二步：验证应用专用密码生成过程"
echo "=============================="

echo "请确认你的生成步骤："
echo "1. 访问 https://appleid.apple.com ✓"
echo "2. 使用主密码（不是应用专用密码）登录 ✓"
echo "3. 进入「登录和安全」部分 ✓"
echo "4. 找到「应用专用密码」选项 ✓"
echo "5. 点击「生成密码...」✓"
echo "6. 输入标签名称 ✓"
echo "7. 复制生成的密码 ✓"
echo ""

read -p "以上步骤都正确执行了吗？(y/n): " steps_correct

if [ "$steps_correct" != "y" ]; then
    echo ""
    echo "❌ 请重新按照正确步骤生成应用专用密码"
    echo "确保："
    echo "- 使用主密码登录Apple ID管理页面"
    echo "- 不是在开发者门户生成"
    echo "- 完整复制密码，包括连字符"
    exit 1
fi

echo ""
echo "请输入刚才生成的新应用专用密码："
read -s new_password
echo ""

if [ -z "$new_password" ]; then
    echo "❌ 密码不能为空"
    exit 1
fi

export FASTLANE_PASSWORD="$new_password"

echo "🔍 第三步：密码格式验证"
echo "==================="

echo "密码: $new_password"
echo "长度: ${#new_password}"

# 检查格式
if [[ $new_password =~ ^[a-z]{4}-[a-z]{4}-[a-z]{4}-[a-z]{4}$ ]]; then
    echo "✅ 格式符合标准规范"
elif [[ $new_password =~ ^[A-Z]{4}-[A-Z]{4}-[A-Z]{4}-[A-Z]{4}$ ]]; then
    echo "⚠️  格式为大写字母，可能需要转换"
    new_password=$(echo "$new_password" | tr '[:upper:]' '[:lower:]')
    export FASTLANE_PASSWORD="$new_password"
    echo "转换后: $new_password"
elif [[ $new_password =~ ^[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}$ ]]; then
    echo "✅ 格式正确（包含数字）"
else
    echo "❌ 格式不符合预期"
    echo "应该是: xxxx-xxxx-xxxx-xxxx"
    echo "当前是: $new_password"
    echo ""
    read -p "是否继续测试？(y/n): " continue_anyway
    if [ "$continue_anyway" != "y" ]; then
        exit 1
    fi
fi

echo ""
echo "🔍 第四步：账号类型检查"
echo "==================="

echo "检查开发者账号状态..."
echo "请访问 https://developer.apple.com 并确认："
echo ""

read -p "1. 你能正常登录开发者门户吗？(y/n): " can_login_dev
read -p "2. 账号是付费开发者账号吗？(y/n): " is_paid_dev
read -p "3. 有未签署的协议吗？(y/n): " has_unsigned_agreements

if [ "$can_login_dev" != "y" ]; then
    echo "❌ 无法登录开发者门户是主要问题"
    echo "可能原因："
    echo "1. 不是开发者账号"
    echo "2. 账号被暂停"
    echo "3. 需要重新激活"
    exit 1
fi

if [ "$is_paid_dev" != "y" ]; then
    echo "❌ 免费账号无法使用FastLane进行远程设备注册"
    echo "解决方案："
    echo "1. 升级到付费开发者账号 ($99/年)"
    echo "2. 使用手动设备注册"
    echo "3. 使用其他付费开发者账号"
    exit 1
fi

if [ "$has_unsigned_agreements" = "y" ]; then
    echo "⚠️  有未签署的协议"
    echo "请先在开发者门户签署所有必要协议"
    echo "然后重新尝试"
    exit 1
fi

echo ""
echo "🔍 第五步：网络和环境检查"
echo "====================="

# 清除所有可能的缓存和会话
rm -rf ~/.fastlane/spaceship_*
rm -rf ~/.fastlane/session_*
rm -rf ~/.fastlane/cookies
rm -rf /tmp/spaceship_*
security delete-generic-password -s "fastlane" 2>/dev/null || true
security delete-generic-password -s "deliver" 2>/dev/null || true

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

cd fastlane

echo "测试基础网络连接..."
if curl -s --connect-timeout 10 https://developer.apple.com > /dev/null; then
    echo "✅ 网络连接正常"
else
    echo "❌ 网络连接问题"
    echo "请检查："
    echo "1. 网络连接"
    echo "2. 防火墙设置"
    echo "3. 是否需要VPN"
    exit 1
fi

echo ""
echo "🧪 第六步：使用不同的登录方法"
echo "========================="

# 方法1: 标准Spaceship登录
echo "方法1: 标准Spaceship登录"
cat > method1_test.rb << 'EOF'
require 'spaceship'

begin
  puts "尝试标准登录..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 方法1成功"
  exit 0
rescue => e
  puts "❌ 方法1失败: #{e.message}"
  puts "错误类型: #{e.class}"
end
EOF

bundle exec ruby method1_test.rb
method1_result=$?
rm -f method1_test.rb

if [ $method1_result -eq 0 ]; then
    echo "🎉 标准登录成功！"
    echo "问题已解决"
    exit 0
fi

echo ""
echo "方法2: 强制清除会话登录"
cat > method2_test.rb << 'EOF'
require 'spaceship'

begin
  puts "清除所有会话..."
  # 强制清除内部会话
  Spaceship::Portal.client = nil if Spaceship::Portal.respond_to?(:client=)
  
  puts "尝试强制登录..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 方法2成功"
  exit 0
rescue => e
  puts "❌ 方法2失败: #{e.message}"
end
EOF

bundle exec ruby method2_test.rb
method2_result=$?
rm -f method2_test.rb

if [ $method2_result -eq 0 ]; then
    echo "🎉 强制登录成功！"
    exit 0
fi

echo ""
echo "方法3: 环境变量调试"
cat > method3_test.rb << 'EOF'
require 'spaceship'

puts "调试信息:"
puts "FASTLANE_USER: #{ENV['FASTLANE_USER']}"
puts "FASTLANE_PASSWORD 长度: #{ENV['FASTLANE_PASSWORD'] ? ENV['FASTLANE_PASSWORD'].length : 'nil'}"
puts "Ruby版本: #{RUBY_VERSION}"

begin
  # 设置调试模式
  ENV['SPACESHIP_DEBUG'] = '1'
  
  puts "\n尝试调试模式登录..."
  Spaceship::Portal.login(ENV['FASTLANE_USER'], ENV['FASTLANE_PASSWORD'])
  puts "✅ 方法3成功"
  exit 0
rescue => e
  puts "❌ 方法3失败: #{e.message}"
  puts "详细错误: #{e.backtrace.first(3).join('\n')}" if e.backtrace
end
EOF

bundle exec ruby method3_test.rb
method3_result=$?
rm -f method3_test.rb

echo ""
echo "📊 诊断结果总结"
echo "=============="

if [ $method1_result -ne 0 ] && [ $method2_result -ne 0 ] && [ $method3_result -ne 0 ]; then
    echo "❌ 所有登录方法都失败了"
    echo ""
    echo "可能的根本原因："
    echo ""
    echo "1. 📧 Apple ID问题："
    echo "   - Apple ID拼写错误"
    echo "   - 账号被锁定或暂停"
    echo "   - 账号需要重新验证"
    echo ""
    echo "2. 🔑 应用专用密码问题："
    echo "   - 复制时包含隐藏字符"
    echo "   - 生成后立即被系统撤销"
    echo "   - 账号未启用应用专用密码功能"
    echo ""
    echo "3. 🏢 账号类型问题："
    echo "   - 不是真正的付费开发者账号"
    echo "   - 开发者权限被撤销"
    echo "   - 团队成员权限不足"
    echo ""
    echo "4. 🌐 环境问题："
    echo "   - 地区限制"
    echo "   - 网络环境问题"
    echo "   - Apple服务器问题"
    echo ""
    echo "🎯 建议的解决步骤："
    echo ""
    echo "1. 【立即验证】在浏览器中："
    echo "   - 访问 https://developer.apple.com"
    echo "   - 使用 $FASTLANE_USER 登录"
    echo "   - 确认能看到开发者资源"
    echo ""
    echo "2. 【重新生成】应用专用密码："
    echo "   - 撤销所有现有的应用专用密码"
    echo "   - 生成全新的密码"
    echo "   - 使用纯文本编辑器复制（避免格式问题）"
    echo ""
    echo "3. 【替代方案】考虑："
    echo "   - 使用其他开发者账号"
    echo "   - 手动在开发者门户注册设备"
    echo "   - 联系Apple Developer Support"
    echo ""
    echo "4. 【环境测试】："
    echo "   - 在不同网络环境下测试"
    echo "   - 尝试使用VPN"
    echo "   - 更新fastlane版本"
else
    echo "🎉 某个方法成功了！"
    echo "可以继续进行设备注册"
fi