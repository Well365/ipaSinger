#!/bin/bash

echo "🚀 启动 MacSigner 应用"
echo "==================="
echo

# 清理可能的 Ruby 环境问题
unset RBENV_VERSION
unset RBENV_ROOT
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"

echo "📱 正在编译应用..."
if swift build; then
    echo "✅ 编译成功"
    echo
    echo "🎯 启动 MacSigner..."
    echo "图形界面将会打开，请按照以下步骤配置 Apple API 凭证："
    echo
    echo "1️⃣ 点击主界面的 '设备管理' 按钮"
    echo "2️⃣ 在设备管理界面，点击 '前往配置' 按钮"
    echo "3️⃣ 在 Apple API 配置窗口中输入："
    echo "   • Key ID: 您的10位Apple API Key ID"
    echo "   • Issuer ID: 您的UUID格式Issuer ID"
    echo "   • Private Key: 完整的P8私钥文件内容"
    echo "4️⃣ 点击 '测试连接' 验证配置"
    echo "5️⃣ 保存配置"
    echo
    echo "📋 应用界面将显示详细的配置表单..."
    echo
    
    # 尝试启动应用
    swift run MacSigner
else
    echo "❌ 编译失败"
    exit 1
fi