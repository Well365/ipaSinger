#!/bin/bash

# MacSigner Session Manager 快速启动脚本
# 快速启动Session管理功能

echo "🚀 MacSigner Session Manager"
echo "============================"
echo ""

# 检查是否在正确的目录
if [ ! -f "Package.swift" ]; then
    echo "❌ 请在 MacSigner 项目根目录运行此脚本"
    echo "💡 提示: cd /path/to/ipaSingerMac && ./quick_session.sh"
    exit 1
fi

echo "📋 当前功能："
echo "  ✅ GUI Session管理界面"
echo "  ✅ 双重认证模式（应用专属密码/账号密码+2FA）"
echo "  ✅ 全局环境变量设置"
echo "  ✅ Session验证和监控"
echo "  ✅ 智能shell配置文件更新"
echo ""

# 检查当前Session状态
echo "📊 当前Session状态："
if [ -n "$FASTLANE_SESSION" ]; then
    echo "  ✅ 环境变量已设置"
    
    # 快速格式检查
    if echo "$FASTLANE_SESSION" | grep -q "myacinfo"; then
        echo "  ✅ 格式正确"
    else
        echo "  ⚠️  格式可能不正确"
    fi
    
    # 检查配置文件
    if grep -q "FASTLANE_SESSION" ~/.zshrc 2>/dev/null; then
        echo "  ✅ 已写入 ~/.zshrc"
    fi
    
    if grep -q "FASTLANE_SESSION" ~/.bash_profile 2>/dev/null; then
        echo "  ✅ 已写入 ~/.bash_profile"
    fi
else
    echo "  ❌ 环境变量未设置"
    echo "  💡 需要通过GUI生成新的Session"
fi

echo ""
echo "🎯 可用操作："
echo "  1. 启动GUI界面管理Session"
echo "  2. 验证当前Session状态"
echo "  3. 查看使用指南"
echo ""

read -p "请选择操作 (1-3): " choice

case $choice in
    1)
        echo "🚀 启动 MacSigner GUI..."
        swift run
        ;;
    2)
        echo "🔍 验证Session状态..."
        if [ -x "./verify_session_token.sh" ]; then
            ./verify_session_token.sh
        else
            echo "❌ 验证脚本不存在，请运行: chmod +x verify_session_token.sh"
        fi
        ;;
    3)
        echo "📖 使用指南："
        echo ""
        echo "基本流程："
        echo "1. 选择操作1启动GUI"
        echo "2. 点击'Session 管理'按钮"
        echo "3. 选择认证方式（推荐：应用专属密码）"
        echo "4. 确保'设置为全局环境变量'已开启"
        echo "5. 输入Apple ID和密码"
        echo "6. 如需要，输入2FA验证码"
        echo "7. 等待认证完成"
        echo ""
        echo "验证方法："
        echo "- 新终端窗口: echo \$FASTLANE_SESSION"
        echo "- 验证脚本: ./verify_session_token.sh"
        echo "- GUI验证: 点击'验证 Session'按钮"
        echo ""
        echo "📄 详细文档: FINAL_SESSION_GUIDE.md"
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac