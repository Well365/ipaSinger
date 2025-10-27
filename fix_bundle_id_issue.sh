#!/bin/bash

echo "🆔 解决 Bundle ID 缺失问题"
echo "=========================="
echo
echo "❌ 错误分析："
echo "FastLane 无法找到 Bundle ID: exam.duo.apih"
echo "这意味着这个 App ID 在您的开发者账号中不存在"
echo
echo "💡 解决方案有三种："
echo

echo "🔧 方案一：使用 FastLane 自动创建 Bundle ID"
echo "========================================="
echo
echo "FastLane 建议的命令："
echo "fastlane produce -u copybytes@163.com -a exam.duo.apih --skip_itc"
echo
echo "参数说明："
echo "  -u: Apple ID 邮箱"
echo "  -a: Bundle ID"
echo "  --skip_itc: 跳过 App Store Connect 配置"
echo
echo "执行步骤："

cat << 'EOF'
cd fastlane
export FASTLANE_USER="copybytes@163.com" 
export FASTLANE_PASSWORD="您的应用专用密码"
bundle exec fastlane produce -a exam.duo.apih --skip_itc
EOF

echo
read -p "是否立即执行方案一？(y/n): " execute_plan1

if [ "$execute_plan1" = "y" ]; then
    echo
    echo "🚀 执行 Bundle ID 创建..."
    
    # 确保在正确目录
    if [ ! -d "fastlane" ]; then
        echo "❌ 未找到 fastlane 目录"
        exit 1
    fi
    
    cd fastlane
    
    # 检查环境变量
    if [ -z "$FASTLANE_USER" ] || [ -z "$FASTLANE_PASSWORD" ]; then
        echo "⚠️  需要设置 Apple ID 凭证"
        read -p "Apple ID: " apple_id
        echo "应用专用密码:"
        read -s app_password
        echo
        
        export FASTLANE_USER="$apple_id"
        export FASTLANE_PASSWORD="$app_password"
    fi
    
    echo "📝 创建 Bundle ID: exam.duo.apih"
    bundle exec fastlane produce -a exam.duo.apih --skip_itc
    
    if [ $? -eq 0 ]; then
        echo "✅ Bundle ID 创建成功！"
        echo
        echo "现在可以重新运行原来的签名流程了："
        echo "cd .."
        echo "./apple_id_password_flow.sh"
    else
        echo "❌ Bundle ID 创建失败"
        echo "请查看错误信息并尝试其他方案"
    fi
    
    exit 0
fi

echo
echo "🌐 方案二：手动在 Developer Portal 创建"
echo "===================================="
echo
echo "1. 访问 Apple Developer Portal"
echo "   https://developer.apple.com/account/"
echo
echo "2. 登录您的开发者账号"
echo
echo "3. 进入 'Certificates, Identifiers & Profiles'"
echo
echo "4. 点击 'Identifiers'"
echo
echo "5. 点击右上角的 '+' 按钮"
echo
echo "6. 选择 'App IDs' 并点击 'Continue'"
echo
echo "7. 选择 'App' 类型并点击 'Continue'"
echo
echo "8. 填写信息："
echo "   - Description: 输入描述（如：PokerFOX App）"
echo "   - Bundle ID: exam.duo.apih"
echo "   - Capabilities: 根据需要选择功能"
echo
echo "9. 点击 'Continue' 然后 'Register'"
echo

echo "🔄 方案三：修改 Bundle ID 匹配现有的"
echo "=================================="
echo
echo "如果您已有其他 App ID，可以修改签名脚本使用现有的："
echo
echo "1. 查看现有的 Bundle ID："
echo "   在 Developer Portal 中查看 Identifiers 列表"
echo
echo "2. 修改脚本中的 BUNDLE_ID 变量："
echo "   例如：BUNDLE_ID=\"com.yourcompany.yourapp\""
echo
echo "3. 重新运行签名流程"
echo

echo "🔍 检查当前开发者账号中的 Bundle ID"
echo "================================"
echo
echo "运行以下命令查看现有的 Bundle ID："

cat << 'EOF'
cd fastlane
export FASTLANE_USER="copybytes@163.com"
export FASTLANE_PASSWORD="您的应用专用密码"
bundle exec fastlane spaceship
EOF

echo
echo "然后在 spaceship 控制台中运行："
echo "Spaceship::Portal.app_ids.each { |app| puts app.bundle_id }"
echo

echo "💡 推荐执行顺序："
echo "==============="
echo "1. 首先尝试方案一（FastLane 自动创建）- 最简单"
echo "2. 如果失败，使用方案二（手动创建）- 最可靠"  
echo "3. 或者使用方案三（修改为现有的）- 最快速"
echo

echo "⚠️  重要提示："
echo "============="
echo "• Bundle ID 一旦创建就无法删除，只能停用"
echo "• 确保 Bundle ID 格式正确（反向域名格式）"
echo "• 免费开发者账号对 Bundle ID 数量有限制"
echo "• 付费开发者账号可以创建无限数量的 Bundle ID"
echo

read -p "选择执行方案 (1/2/3) 或按 Enter 退出: " choice

case $choice in
    1)
        echo "请重新运行脚本并选择 'y' 执行方案一"
        ;;
    2)
        echo "请访问 https://developer.apple.com/account/ 手动创建"
        ;;
    3)
        echo "请修改 apple_id_password_flow.sh 中的 BUNDLE_ID 变量"
        ;;
    *)
        echo "退出。请选择合适的方案解决 Bundle ID 问题。"
        ;;
esac