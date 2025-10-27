#!/bin/bash

echo "🔑 Apple 应用专用密码生成指南"
echo "============================"
echo
echo "✅ Bundle ID 已成功创建：exam.duo.apih"
echo "现在需要生成应用专用密码来完成签名流程"
echo

echo "📱 第一步：访问 Apple ID 管理页面"
echo "=============================="
echo "🌐 在浏览器中打开：https://appleid.apple.com"
echo
echo "登录步骤："
echo "1. 输入您的 Apple ID: copybytes@163.com"
echo "2. 输入密码"
echo "3. 完成双因素认证（如果需要）"
echo

echo "🔐 第二步：生成应用专用密码"
echo "========================"
echo "进入页面后："
echo "1. 找到「登录和安全」部分"
echo "2. 滚动到「应用专用密码」部分"
echo "3. 点击「生成密码...」按钮"
echo "4. 输入标签名称，例如：'FastLane-IPA-Signer'"
echo "5. 点击「创建」"
echo "6. 复制显示的密码（格式：xxxx-xxxx-xxxx-xxxx）"
echo "7. ⚠️ 重要：立即保存这个密码，页面关闭后无法再查看！"
echo

echo "📋 密码格式示例："
echo "abcd-efgh-ijkl-mnop"
echo "（4组4位字符，用连字符分隔）"
echo

echo "💡 为什么需要应用专用密码？"
echo "========================"
echo "• 启用了双因素认证的 Apple ID 无法直接用于第三方应用"
echo "• 应用专用密码是专门为自动化工具（如 FastLane）设计的"
echo "• 更安全：可以单独撤销，不影响主账户安全"
echo "• 每个应用可以使用不同的专用密码"
echo

echo "⚡ 快速测试应用专用密码"
echo "===================="
echo "生成密码后，可以使用以下命令快速测试："
echo
echo "cd fastlane"
echo "export FASTLANE_USER=\"copybytes@163.com\""
echo "export FASTLANE_PASSWORD=\"您的应用专用密码\""
echo "bundle exec fastlane login"
echo

echo "🔧 完成后的下一步"
echo "================"
echo "1. 生成应用专用密码"
echo "2. 重新运行：./apple_id_password_flow.sh"
echo "3. 选择 'y' 确认已生成密码"
echo "4. 输入 Apple ID 和应用专用密码"
echo "5. 完成 IPA 签名流程"
echo

echo "🚨 常见问题"
echo "=========="
echo "Q: 找不到「应用专用密码」选项？"
echo "A: 确保已启用双因素认证，且账号类型支持此功能"
echo
echo "Q: 生成密码时出错？"
echo "A: 可能是网络问题，稍后重试或换个浏览器"
echo
echo "Q: 密码格式不对？"
echo "A: 确保复制完整的密码，包括连字符"
echo

read -p "是否现在就去生成应用专用密码？(y/n): " go_generate

if [ "$go_generate" = "y" ]; then
    echo
    echo "🚀 正在为您打开 Apple ID 管理页面..."
    
    # 尝试用默认浏览器打开
    if command -v open >/dev/null 2>&1; then
        open "https://appleid.apple.com/account/manage"
        echo "✅ 已在浏览器中打开 Apple ID 管理页面"
    else
        echo "请手动访问：https://appleid.apple.com/account/manage"
    fi
    
    echo
    echo "📝 请按照页面指引生成应用专用密码"
    echo "生成完成后，运行以下命令继续："
    echo
    echo "./apple_id_password_flow.sh"
    echo
else
    echo
    echo "💡 记住访问：https://appleid.apple.com/account/manage"
    echo "生成应用专用密码后重新运行签名流程"
fi

echo
echo "🎯 总结：您已完成 50% 的工作！"
echo "==============================="
echo "✅ Bundle ID 创建成功：exam.duo.apih"
echo "🔲 应用专用密码：待生成"
echo "🔲 IPA 签名：待执行"
echo
echo "下一步：生成应用专用密码 → 运行签名流程 → 完成！"