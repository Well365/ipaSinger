#!/bin/bash

echo "🍎 Apple Developer API 测试脚本"
echo "============================="
echo ""

echo "这个脚本将测试Apple Developer API集成，替代FastLane方案"
echo ""

# 检查是否有配置
if [ -z "$APPLE_API_KEY_ID" ] && [ -z "$(defaults read com.apple.dt.Xcode AppleAPIKeyID 2>/dev/null)" ]; then
    echo "❌ 未找到Apple API配置"
    echo ""
    echo "请按以下步骤配置："
    echo ""
    echo "1. 打开应用程序"
    echo "2. 点击「Apple API」按钮"
    echo "3. 按照指引配置API密钥"
    echo ""
    echo "或者手动设置环境变量："
    echo "export APPLE_API_KEY_ID=\"你的Key ID\""
    echo "export APPLE_API_ISSUER_ID=\"你的Issuer ID\""
    echo "export APPLE_API_PRIVATE_KEY=\"你的私钥内容\""
    echo ""
    exit 1
fi

echo "✅ 检测到Apple API配置"
echo ""

echo "📋 使用Apple Developer API的优势："
echo ""
echo "✅ 无需应用专用密码"
echo "✅ 更稳定的认证机制"
echo "✅ 更精确的错误信息"
echo "✅ 支持自动化脚本"
echo "✅ 避免双重认证问题"
echo ""

echo "🔧 支持的功能："
echo ""
echo "1. 自动设备注册"
echo "2. 证书管理"
echo "3. Bundle ID管理"
echo "4. Provisioning Profile创建和管理"
echo "5. IPA重新签名"
echo ""

echo "🚀 下一步骤："
echo ""
echo "1. 在应用中点击「本地签名」"
echo "2. 选择要重新签名的IPA文件"
echo "3. 输入设备UDID（设置 → 通用 → 关于本机 → 设备标识符）"
echo "4. 输入Bundle ID（如: com.yourcompany.yourapp）"
echo "5. 点击「使用Apple API签名」"
echo ""

echo "📱 获取UDID的方法："
echo ""
echo "方法1 - 设备设置:"
echo "设置 → 通用 → 关于本机 → 往下滑动找到「设备标识符」"
echo ""
echo "方法2 - iTunes/Finder:"
echo "连接设备到电脑，在iTunes或Finder中查看设备信息"
echo ""
echo "方法3 - Xcode:"
echo "Xcode → Window → Devices and Simulators → 选择设备"
echo ""

echo "⚡ 自动化流程："
echo ""
echo "整个过程将自动完成以下步骤："
echo "1. 使用API Key认证Apple Developer账号"
echo "2. 检查设备是否已注册，未注册则自动注册"
echo "3. 获取可用的开发证书"
echo "4. 查找或创建适当的Provisioning Profile"
echo "5. 下载Provisioning Profile"
echo "6. 解压IPA，替换配置文件"
echo "7. 重新签名所有组件"
echo "8. 重新打包为新的IPA"
echo ""

echo "🎯 与FastLane方案的对比："
echo ""
echo "FastLane方案:"
echo "❌ 需要应用专用密码"
echo "❌ 认证经常失败"
echo "❌ 依赖Ruby环境"
echo "❌ 错误信息不清晰"
echo ""
echo "Apple API方案:"
echo "✅ 使用官方API Key认证"
echo "✅ 认证稳定可靠"
echo "✅ 纯Swift实现"
echo "✅ 详细的错误信息和日志"
echo ""

echo "🔍 调试信息："
echo ""
if [ -n "$APPLE_API_KEY_ID" ]; then
    echo "Key ID: $APPLE_API_KEY_ID"
else
    echo "Key ID: (从UserDefaults读取)"
fi

if [ -n "$APPLE_API_ISSUER_ID" ]; then
    echo "Issuer ID: ${APPLE_API_ISSUER_ID:0:8}..."
else
    echo "Issuer ID: (从UserDefaults读取)"
fi

if [ -n "$APPLE_API_PRIVATE_KEY" ]; then
    echo "私钥: 已设置 (${#APPLE_API_PRIVATE_KEY} 字符)"
else
    echo "私钥: (从UserDefaults读取)"
fi

echo ""
echo "✨ 准备就绪！现在可以开始使用Apple API进行IPA重新签名了"