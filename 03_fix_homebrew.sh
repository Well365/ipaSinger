#!/bin/bash

# Homebrew 环境修复脚本
# 解决常见的 Homebrew 配置问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 Homebrew 环境修复工具"
echo "========================="
echo

# 检查 Homebrew 是否安装
if ! command -v brew &>/dev/null; then
    log_error "Homebrew 未安装，请先安装 Homebrew"
    exit 1
fi

log_info "当前 Homebrew 版本: $(brew --version | head -n1)"
echo

# 1. 清理废弃的 taps
log_info "步骤 1: 清理废弃的 taps..."
deprecated_taps=(
    "homebrew/homebrew-cask-fonts"
    "homebrew/cask-fonts"
)

for tap in "${deprecated_taps[@]}"; do
    if brew tap | grep -q "$tap"; then
        log_info "移除废弃的 tap: $tap"
        brew untap "$tap" 2>/dev/null || true
    fi
done

log_success "废弃 taps 清理完成"
echo

# 2. 检查并修复 Git 配置
log_info "步骤 2: 检查 Git 配置..."

# 检查 Git 用户配置
if ! git config --global user.name >/dev/null 2>&1; then
    log_warning "Git 用户名未配置"
    read -p "请输入您的 Git 用户名: " git_username
    git config --global user.name "$git_username"
    log_success "Git 用户名已设置为: $git_username"
fi

if ! git config --global user.email >/dev/null 2>&1; then
    log_warning "Git 邮箱未配置"
    read -p "请输入您的 Git 邮箱: " git_email
    git config --global user.email "$git_email"
    log_success "Git 邮箱已设置为: $git_email"
fi

# 配置 Git 凭据助手
if [[ "$(uname)" == "Darwin" ]]; then
    git config --global credential.helper osxkeychain
    log_info "已配置 macOS 钥匙串凭据助手"
fi

echo

# 3. 更新 Homebrew
log_info "步骤 3: 更新 Homebrew..."

if brew update; then
    log_success "Homebrew 更新成功"
else
    log_warning "Homebrew 更新失败，尝试诊断..."
    
    # 运行诊断
    log_info "运行 Homebrew 诊断..."
    if brew doctor; then
        log_success "Homebrew 诊断通过"
    else
        log_warning "Homebrew 诊断发现问题，请根据上述建议手动修复"
    fi
fi

echo

# 4. 清理 Homebrew 缓存
log_info "步骤 4: 清理 Homebrew 缓存..."
brew cleanup --prune=all
log_success "Homebrew 缓存清理完成"
echo

# 5. 显示当前状态
log_info "步骤 5: 显示当前状态..."
echo "🍺 Homebrew 信息:"
echo "  版本: $(brew --version | head -n1)"
echo "  前缀: $(brew --prefix)"
echo "  仓库: $(brew --repository)"
echo

echo "📦 已安装的 Taps:"
brew tap | sed 's/^/  /'
echo

echo "🔍 系统检查:"
outdated_count=$(brew outdated | wc -l)
echo "  过期软件包: $outdated_count 个"

if [[ $outdated_count -gt 0 ]]; then
    log_info "可以运行 'brew upgrade' 来更新过期的软件包"
fi

echo
log_success "Homebrew 环境修复完成！"
log_info "建议重新启动终端或运行 'source ~/.zshrc' 来确保配置生效"