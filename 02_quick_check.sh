#!/bin/bash

# 快速环境验证脚本
# 用于快速检查当前 iOS 开发环境状态

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 iOS 开发环境快速检查"
echo "========================="
echo

# 系统信息
echo "📱 系统信息："
echo "  macOS: $(sw_vers -productVersion)"
echo "  架构: $(uname -m)"
echo

# 开发工具检查
echo "🛠️ 开发工具："

echo -n "  Xcode Tools: "
if xcode-select --print-path &>/dev/null; then
    echo -e "${GREEN}✅ 已安装${NC} ($(xcode-select --print-path))"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "  Homebrew: "
if command -v brew &>/dev/null; then
    echo -e "${GREEN}✅ $(brew --version | head -n1)${NC}"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "  Swift: "
if command -v swift &>/dev/null; then
    echo -e "${GREEN}✅ $(swift --version | head -n1)${NC}"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo

# Ruby 环境检查
echo "💎 Ruby 环境："

echo -n "  rbenv: "
if command -v rbenv &>/dev/null; then
    echo -e "${GREEN}✅ $(rbenv --version)${NC}"
    
    echo "  已安装的 Ruby 版本："
    rbenv versions | sed 's/^/    /'
    
    if [[ -f ".ruby-version" ]]; then
        project_ruby=$(cat .ruby-version)
        echo "  项目指定版本: $project_ruby"
    fi
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "  当前 Ruby: "
if command -v ruby &>/dev/null; then
    current_ruby=$(ruby --version)
    if [[ -f ".ruby-version" ]] && [[ "$current_ruby" == *"$(cat .ruby-version)"* ]]; then
        echo -e "${GREEN}✅ $current_ruby${NC}"
    else
        echo -e "${YELLOW}⚠️ $current_ruby${NC}"
        if [[ -f ".ruby-version" ]]; then
            echo -e "    ${YELLOW}注意: 当前版本与项目指定版本不匹配${NC}"
        fi
    fi
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo -n "  Bundler: "
if command -v bundler &>/dev/null; then
    echo -e "${GREEN}✅ $(bundler --version)${NC}"
else
    echo -e "${RED}❌ 未安装${NC}"
fi

echo

# Swift 项目检查
if [[ -f "Package.swift" ]]; then
    echo "📦 Swift 项目："
    echo -n "  Package.swift: "
    echo -e "${GREEN}✅ 存在${NC}"
    
    echo -n "  构建缓存: "
    if [[ -d ".build" ]]; then
        echo -e "${YELLOW}⚠️ 存在 (.build 目录)${NC}"
        echo "    建议: 如有问题可清理缓存 (rm -rf .build)"
    else
        echo -e "${GREEN}✅ 清洁${NC}"
    fi
    
    echo -n "  依赖状态: "
    if [[ -f "Package.resolved" ]]; then
        echo -e "${GREEN}✅ 已解析${NC}"
    else
        echo -e "${YELLOW}⚠️ 未解析${NC}"
        echo "    建议: 运行 swift package resolve"
    fi
    echo
fi

# Fastlane 检查
if [[ -d "fastlane" ]]; then
    echo "🚀 Fastlane："
    
    echo -n "  Gemfile: "
    if [[ -f "fastlane/Gemfile" ]]; then
        echo -e "${GREEN}✅ 存在${NC}"
    else
        echo -e "${RED}❌ 不存在${NC}"
    fi
    
    echo -n "  Bundle 配置: "
    if [[ -f "fastlane/.bundle/config" ]]; then
        echo -e "${GREEN}✅ 已配置${NC}"
        bundle_path=$(grep "BUNDLE_PATH" fastlane/.bundle/config 2>/dev/null | cut -d'"' -f2)
        if [[ -n "$bundle_path" ]]; then
            echo "    路径: $bundle_path"
        fi
    else
        echo -e "${YELLOW}⚠️ 未配置${NC}"
    fi
    
    echo -n "  Gems 安装: "
    if [[ -d "fastlane/vendor/bundle" ]]; then
        echo -e "${GREEN}✅ 已安装 (vendor/bundle)${NC}"
        
        cd fastlane
        if bundle check &>/dev/null; then
            echo "    状态: 依赖满足"
        else
            echo -e "    状态: ${YELLOW}需要更新${NC}"
        fi
        cd ..
    else
        echo -e "${RED}❌ 未安装${NC}"
    fi
    
    echo -n "  Fastlane 可用性: "
    cd fastlane
    if bundle exec fastlane --version &>/dev/null; then
        fastlane_version=$(bundle exec fastlane --version 2>/dev/null | grep "fastlane" | head -n1)
        echo -e "${GREEN}✅ $fastlane_version${NC}"
    else
        echo -e "${RED}❌ 无法运行${NC}"
    fi
    cd ..
    echo
fi

# 建议操作
echo "💡 建议操作："

if ! command -v rbenv &>/dev/null; then
    echo "  • 安装 rbenv: brew install rbenv ruby-build"
fi

if [[ -f ".ruby-version" ]] && command -v ruby &>/dev/null; then
    current_ruby=$(ruby --version)
    project_ruby=$(cat .ruby-version)
    if [[ "$current_ruby" != *"$project_ruby"* ]]; then
        echo "  • 切换 Ruby 版本: rbenv install $project_ruby && rbenv rehash"
    fi
fi

if [[ -d "fastlane" ]] && [[ ! -d "fastlane/vendor/bundle" ]]; then
    echo "  • 安装 Fastlane: cd fastlane && bundle install --path vendor/bundle"
fi

if [[ -f "Package.swift" ]] && [[ ! -f "Package.resolved" ]]; then
    echo "  • 解析 Swift 依赖: swift package resolve"
fi

echo
echo "🎯 快速修复命令："
echo "  ./setup_check.sh              # 运行完整环境配置"
echo "  source ~/.zshrc                # 重新加载 shell 配置"
echo "  rbenv rehash                   # 刷新 rbenv"
echo "  swift package clean            # 清理 Swift 缓存"

echo
echo "✨ 检查完成！"