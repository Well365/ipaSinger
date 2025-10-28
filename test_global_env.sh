#!/bin/bash

echo "=== 测试全局环境变量设置功能 ==="
echo ""

# 检查当前的 FASTLANE_SESSION
echo "1. 当前环境变量:"
echo "FASTLANE_SESSION = $FASTLANE_SESSION"
echo ""

# 检查shell配置文件
echo "2. 检查shell配置文件:"

if [ -f ~/.zshrc ]; then
    echo "~/.zshrc 中的 FASTLANE_SESSION 配置:"
    grep -n "FASTLANE_SESSION" ~/.zshrc || echo "未找到 FASTLANE_SESSION 配置"
    echo ""
fi

if [ -f ~/.bash_profile ]; then
    echo "~/.bash_profile 中的 FASTLANE_SESSION 配置:"
    grep -n "FASTLANE_SESSION" ~/.bash_profile || echo "未找到 FASTLANE_SESSION 配置"
    echo ""
fi

if [ -f ~/.profile ]; then
    echo "~/.profile 中的 FASTLANE_SESSION 配置:"
    grep -n "FASTLANE_SESSION" ~/.profile || echo "未找到 FASTLANE_SESSION 配置"
    echo ""
fi

# 测试在新shell中是否可用
echo "3. 测试新shell环境："
echo "在新的shell会话中测试环境变量..."
/bin/zsh -c 'echo "新zsh会话中的 FASTLANE_SESSION = $FASTLANE_SESSION"'
/bin/bash -c 'echo "新bash会话中的 FASTLANE_SESSION = $FASTLANE_SESSION"'

echo ""
echo "=== 测试完成 ==="