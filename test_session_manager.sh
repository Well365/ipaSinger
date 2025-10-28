#!/bin/bash

# 测试 Session Manager 功能

echo "🧪 Session Manager 功能测试"
echo "=========================="
echo ""

echo "📋 测试环境检查:"
echo "当前目录: $(pwd)"
echo "当前用户: $(whoami)"
echo "Shell: $SHELL"
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
    echo ""
    
    if command -v rbenv >/dev/null 2>&1; then
        echo "✅ rbenv 已安装"
        echo "当前 Ruby 版本: $(rbenv version)"
        
        if test -f .ruby-version; then
            echo "项目 Ruby 版本: $(cat .ruby-version)"
        fi
        
        if test -d vendor/bundle; then
            echo "✅ Bundle 依赖已安装"
            echo "测试 fastlane 命令:"
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
echo "📱 通知权限检查:"
osascript -e 'display notification "这是一个测试通知" with title "Session Manager 测试"' 2>/dev/null && echo "✅ 通知权限正常" || echo "❌ 通知权限问题"

echo ""
echo "🚀 Session Manager 界面准备就绪!"
echo "请在 MacSigner 应用中点击 'Session 管理' 按钮进行测试"
echo ""
echo "📝 测试步骤:"
echo "1. 点击 'Session 管理' 按钮"
echo "2. 输入您的 Apple ID 和应用专用密码"
echo "3. 点击 '开始认证'"
echo "4. 如果需要，输入双重认证码"
echo "5. 确认 Session Token 设置成功"
echo "6. 验证环境变量自动设置"
echo "7. 测试到期提醒功能"