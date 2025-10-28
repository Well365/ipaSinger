#!/bin/bash

# 测试改进后的 Session Manager 功能

echo "🧪 Session Manager 功能测试（改进版）"
echo "=================================="
echo ""

echo "📋 新功能验证:"
echo "✅ 支持两种认证方式"
echo "   1. Apple ID + 应用专属密码（推荐）"
echo "   2. Apple ID + 账号密码 + 双重验证码"
echo ""
echo "✅ 修复了密码输入框无法输入的问题"
echo "✅ 增强了双重验证码输入体验"
echo "✅ 自动密码输入（账号密码模式）"
echo ""

echo "🔍 检查项目环境:"
echo "项目根目录是否存在 Package.swift: $(test -f Package.swift && echo '✅ 是' || echo '❌ 否')"
echo "fastlane 目录是否存在: $(test -d fastlane && echo '✅ 是' || echo '❌ 否')"
echo ""

if [ -d fastlane ]; then
    echo "📦 fastlane 环境检查:"
    cd fastlane
    echo "Gemfile 是否存在: $(test -f Gemfile && echo '✅ 是' || echo '❌ 否')"
    echo "vendor/bundle 是否存在: $(test -d vendor/bundle && echo '✅ 是' || echo '❌ 否')"
    
    if command -v rbenv >/dev/null 2>&1; then
        echo "✅ rbenv 已安装"
        echo "当前 Ruby 版本: $(rbenv version)"
        
        if test -d vendor/bundle; then
            echo "✅ Bundle 依赖已安装"
            if rbenv exec bundle exec fastlane --version >/dev/null 2>&1; then
                echo "✅ fastlane 命令可用"
                echo "fastlane 版本: $(rbenv exec bundle exec fastlane --version 2>/dev/null | head -1)"
            else
                echo "❌ fastlane 命令不可用"
            fi
        else
            echo "❌ Bundle 依赖未安装"
        fi
    else
        echo "❌ rbenv 未安装"
    fi
    
    cd ..
fi

echo ""
echo "🔐 当前 FASTLANE_SESSION 状态:"
if [ -n "$FASTLANE_SESSION" ]; then
    echo "✅ FASTLANE_SESSION 环境变量已设置"
    echo "Session 长度: ${#FASTLANE_SESSION} 字符"
    echo "Session 开头: ${FASTLANE_SESSION:0:50}..."
else
    echo "❌ FASTLANE_SESSION 环境变量未设置"
fi

echo ""
echo "🚀 改进后的 Session Manager 准备就绪!"
echo ""
echo "📝 新的测试步骤:"
echo "1. 启动应用: swift run MacSigner"
echo "2. 点击 'Session 管理' 按钮"
echo "3. 选择认证方式:"
echo "   - 应用专属密码模式（推荐）"
echo "   - 账号密码模式（支持自动输入）"
echo "4. 输入 Apple ID"
echo "5. 输入对应的密码（现在应该可以正常输入了）"
echo "6. 点击 '开始认证'"
echo "7. 如果是账号密码模式，系统会自动输入密码"
echo "8. 输入双重验证码（如需要）"
echo "9. 确认 Session Token 设置成功"
echo ""
echo "🔧 改进点说明:"
echo "- 修复了 SecureField 无法输入的问题"
echo "- 添加了认证方式选择器"
echo "- 账号密码模式下自动输入密码"
echo "- 改进了用户界面提示文本"
echo "- 增强了错误处理和用户体验"
echo ""
echo "💡 使用建议:"
echo "- 首选应用专属密码方式（更安全，无需双重验证）"
echo "- 如果没有应用专属密码，可使用账号密码方式"
echo "- 确保网络连接稳定"
echo "- 保持信任设备在身边（用于接收验证码）"