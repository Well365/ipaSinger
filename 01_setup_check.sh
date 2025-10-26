#!/bin/bash

# macOS iOS 开发环境一键检查和配置脚本
# 适用于 macOS (Intel/Apple Silicon)
# 用途：自动检查和配置 iOS 开发环境，包括多环境自动切换

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 日志函数
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 检查是否为项目目录
check_project_directory() {
    if [[ ! -f "Package.swift" ]] && [[ ! -d "fastlane" ]]; then
        log_warning "当前目录似乎不是 iOS 项目目录"
        log_info "建议在包含 Package.swift 或 fastlane 目录的项目根目录运行此脚本"
        read -p "是否继续？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查并安装 Xcode Command Line Tools
check_xcode_tools() {
    log_step "检查 Xcode Command Line Tools..."
    
    if xcode-select --print-path &>/dev/null; then
        log_success "Xcode Command Line Tools 已安装"
        log_info "路径: $(xcode-select --print-path)"
        
        # 检查版本
        if command -v xcodebuild &>/dev/null; then
            xcode_version=$(xcodebuild -version | head -n1)
            log_info "版本: $xcode_version"
        fi
    else
        log_warning "Xcode Command Line Tools 未安装，开始安装..."
        xcode-select --install
        log_info "请在弹出的对话框中完成安装，然后重新运行此脚本"
        exit 1
    fi
}

# 检查并安装 Homebrew
check_homebrew() {
    log_step "检查 Homebrew..."
    
    if command -v brew &>/dev/null; then
        log_success "Homebrew 已安装"
        brew_version=$(brew --version | head -n1)
        log_info "版本: $brew_version"
        
        # 清理可能存在的问题 taps
        log_info "清理 Homebrew 配置..."
        brew untap homebrew/homebrew-cask-fonts 2>/dev/null || true
        
        log_info "更新 Homebrew..."
        if ! brew update 2>/dev/null; then
            log_warning "Homebrew 更新遇到问题，尝试修复..."
            # 尝试修复常见问题
            brew doctor --quiet 2>/dev/null || true
            log_info "已执行 Homebrew 诊断，继续执行"
        fi
    else
        log_warning "Homebrew 未安装，开始安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # 添加到 PATH
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log_success "Homebrew 安装完成"
    fi
}

# 检查并安装 rbenv
check_rbenv() {
    log_step "检查 rbenv..."
    
    if command -v rbenv &>/dev/null; then
        log_success "rbenv 已安装"
        rbenv_version=$(rbenv --version)
        log_info "版本: $rbenv_version"
    else
        log_warning "rbenv 未安装，开始安装..."
        brew install rbenv ruby-build
        
        # 添加到 shell 配置
        shell_config=""
        if [[ $SHELL == *"zsh"* ]]; then
            shell_config="$HOME/.zshrc"
        elif [[ $SHELL == *"bash"* ]]; then
            shell_config="$HOME/.bash_profile"
        fi
        
        if [[ -n "$shell_config" ]]; then
            if ! grep -q 'rbenv init' "$shell_config" 2>/dev/null; then
                echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$shell_config"
                echo 'eval "$(rbenv init -)"' >> "$shell_config"
                log_info "已添加 rbenv 配置到 $shell_config"
            fi
        fi
        
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        
        log_success "rbenv 安装完成"
    fi
}

# 智能 Ruby 版本管理
manage_ruby_versions() {
    log_step "管理 Ruby 版本..."
    
    # 目标 Ruby 版本
    target_ruby="3.2.8"
    
    # 检查已安装的 Ruby 版本
    installed_versions=$(rbenv versions --bare)
    log_info "已安装的 Ruby 版本:"
    echo "$installed_versions" | sed 's/^/  /'
    
    # 检查是否已安装目标版本
    if echo "$installed_versions" | grep -q "^$target_ruby$"; then
        log_success "Ruby $target_ruby 已安装"
    else
        log_warning "Ruby $target_ruby 未安装，开始安装..."
        log_info "这个过程可能需要 5-10 分钟，请耐心等待..."
        
        # 设置编译选项（优化性能）
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)"
        
        rbenv install "$target_ruby"
        log_success "Ruby $target_ruby 安装完成"
    fi
    
    # 检查和设置项目 Ruby 版本
    if [[ -f ".ruby-version" ]]; then
        current_version=$(cat .ruby-version)
        if [[ "$current_version" == "$target_ruby" ]]; then
            log_success "项目 Ruby 版本已设置为 $target_ruby"
        else
            log_info "当前项目版本: $current_version，更新到 $target_ruby"
            echo "$target_ruby" > .ruby-version
            log_success "项目 Ruby 版本已更新"
        fi
    else
        log_info "创建 .ruby-version 文件"
        echo "$target_ruby" > .ruby-version
        log_success ".ruby-version 文件已创建"
    fi
    
    # 刷新 rbenv 并检查切换结果
    rbenv rehash
    
    # 验证 Ruby 版本切换
    current_ruby=$(ruby --version 2>/dev/null || echo "无法检测")
    log_info "当前 Ruby 版本: $current_ruby"
    
    # 如果版本不正确，尝试修复
    if [[ "$current_ruby" != *"$target_ruby"* ]]; then
        log_warning "Ruby 版本切换可能未生效，尝试修复..."
        
        # 重新初始化 rbenv
        eval "$(rbenv init -)"
        rbenv shell "$target_ruby" 2>/dev/null || true
        
        # 再次检查
        current_ruby=$(ruby --version 2>/dev/null || echo "仍然无法检测")
        if [[ "$current_ruby" == *"$target_ruby"* ]]; then
            log_success "Ruby 版本切换成功"
        else
            log_warning "Ruby 版本切换可能需要重新启动终端"
            log_info "建议执行: source ~/.zshrc 或重新启动终端"
        fi
    fi
}

# 智能 Bundler 管理
check_bundler() {
    log_step "检查和配置 Bundler..."
    
    # 检查 Bundler 是否安装
    if command -v bundler &>/dev/null; then
        bundler_version=$(bundler --version)
        log_success "Bundler 已安装: $bundler_version"
        
        # 检查版本兼容性
        if bundler --version | grep -q "2\.[0-3]\."; then
            log_info "当前 Bundler 版本较旧但兼容"
        fi
    else
        log_warning "Bundler 未安装，开始安装兼容版本..."
        
        # 安装兼容的 Bundler 版本
        gem install bundler -v 2.4.22
        log_success "Bundler 2.4.22 安装完成"
    fi
    
    # 检查 gem 更新
    log_info "检查 gem 环境..."
    gem_version=$(gem --version)
    log_info "RubyGems 版本: $gem_version"
}

# Swift 环境检查和优化
check_swift() {
    log_step "检查 Swift 环境..."
    
    if command -v swift &>/dev/null; then
        swift_version=$(swift --version | head -n1)
        log_success "Swift 已安装: $swift_version"
        
        # 检查项目是否为 Swift 项目
        if [[ -f "Package.swift" ]]; then
            log_info "检测到 Swift 项目"
            
            # 清理可能的构建缓存问题
            if [[ -d ".build" ]]; then
                log_info "发现旧的构建缓存，清理中..."
                rm -rf .build
                swift package clean 2>/dev/null || true
                log_success "构建缓存已清理"
            fi
            
            # 检查和解析依赖
            log_info "解析项目依赖..."
            if swift package resolve; then
                log_success "项目依赖解析完成"
                
                # 尝试构建以验证环境
                log_info "验证构建环境..."
                if swift build --quiet; then
                    log_success "Swift 项目构建成功"
                else
                    log_warning "Swift 项目构建失败，可能需要手动检查"
                fi
            else
                log_warning "依赖解析失败，可能需要手动检查 Package.swift"
            fi
        fi
    else
        log_error "Swift 未安装，请安装 Xcode"
        return 1
    fi
}

# Fastlane 环境检查和配置
check_fastlane() {
    log_step "检查 Fastlane 环境..."
    
    if [[ -d "fastlane" ]]; then
        log_info "发现 Fastlane 目录"
        cd fastlane
        
        if [[ -f "Gemfile" ]]; then
            log_info "发现 Gemfile，配置 Fastlane 环境..."
            
            # 检查和配置本地 bundle 路径
            if [[ ! -f ".bundle/config" ]]; then
                log_info "配置 Bundle 本地安装路径..."
                bundle config set --local path 'vendor/bundle'
            fi
            
            # 检查现有 bundle
            if [[ -d "vendor/bundle" ]]; then
                log_info "发现现有 bundle 安装，检查状态..."
                if bundle check &>/dev/null; then
                    log_success "Bundle 依赖已满足"
                else
                    log_info "Bundle 依赖需要更新..."
                    bundle install
                fi
            else
                log_info "首次安装 Fastlane 依赖..."
                bundle install
            fi
            
            # 验证 Fastlane 安装
            if bundle exec fastlane --version &>/dev/null; then
                fastlane_version=$(bundle exec fastlane --version 2>/dev/null | grep "fastlane" | head -n1)
                log_success "Fastlane 配置成功: $fastlane_version"
                
                # 检查可用的 lanes
                if [[ -f "Fastfile" ]]; then
                    log_info "检查可用的 Fastlane lanes..."
                    available_lanes=$(bundle exec fastlane lanes 2>/dev/null | grep "-----" -A 100 | grep "fastlane" | wc -l)
                    if [[ $available_lanes -gt 0 ]]; then
                        log_info "发现 $available_lanes 个可用的 lanes"
                    fi
                fi
            else
                log_error "Fastlane 配置失败"
                cd ..
                return 1
            fi
        else
            log_warning "fastlane 目录中未找到 Gemfile"
        fi
        
        cd ..
    else
        log_info "未发现 fastlane 目录，跳过 Fastlane 配置"
    fi
}

# 环境检查总结
show_environment_summary() {
    log_step "环境配置总结"
    echo
    echo "🔧 系统信息："
    echo "  macOS: $(sw_vers -productVersion)"
    echo "  架构: $(uname -m)"
    echo "  Shell: $SHELL"
    echo
    echo "🛠️ 开发工具："
    if command -v xcode-select &>/dev/null; then
        echo "  ✅ Xcode Tools: $(xcode-select --print-path | sed 's|/CommandLineTools||' | sed 's|/Applications/Xcode.app/Contents/Developer|Xcode|')"
    fi
    if command -v brew &>/dev/null; then
        echo "  ✅ Homebrew: $(brew --version | head -n1 | sed 's/Homebrew //')"
    fi
    if command -v swift &>/dev/null; then
        echo "  ✅ Swift: $(swift --version | head -n1 | sed 's/.*Swift version //' | sed 's/ .*//')"
    fi
    echo
    echo "💎 Ruby 环境："
    if command -v rbenv &>/dev/null; then
        echo "  ✅ rbenv: $(rbenv --version | sed 's/rbenv //')"
    fi
    if command -v ruby &>/dev/null; then
        echo "  ✅ Ruby: $(ruby --version | sed 's/ruby //' | sed 's/ .*//')"
        if [[ -f ".ruby-version" ]]; then
            echo "  📁 项目版本: $(cat .ruby-version)"
        fi
    fi
    if command -v bundler &>/dev/null; then
        echo "  ✅ Bundler: $(bundler --version | sed 's/Bundler version //')"
    fi
    echo
    
    # Fastlane 信息
    if [[ -d "fastlane" ]]; then
        echo "🚀 Fastlane："
        cd fastlane
        if bundle exec fastlane --version &>/dev/null 2>&1; then
            fastlane_info=$(bundle exec fastlane --version 2>/dev/null | grep "fastlane" | head -n1)
            echo "  ✅ $fastlane_info"
            
            # 显示安装位置
            bundle_path=$(bundle config get path 2>/dev/null | sed 's/.*"//' | sed 's/".*//')
            if [[ -n "$bundle_path" ]]; then
                echo "  📦 Bundle 路径: $bundle_path"
            fi
        else
            echo "  ❌ 未正确配置"
        fi
        cd ..
    fi
    
    echo
    echo "📋 使用建议："
    echo "  • Swift 项目: swift build"
    echo "  • 清理缓存: swift package clean && rm -rf .build"
    if [[ -d "fastlane" ]]; then
        echo "  • Fastlane: cd fastlane && bundle exec fastlane [lane_name]"
    fi
    echo
    log_success "环境配置完成！你现在可以开始开发 iOS 应用了 🎉"
}

# 错误处理
handle_error() {
    log_error "脚本执行过程中遇到错误"
    log_info "请检查上述输出信息，或手动执行相应步骤"
    exit 1
}

# 主函数
main() {
    echo "🍎 macOS iOS 开发环境一键配置脚本"
    echo "====================================="
    echo "  版本: 1.0.0"
    echo "  适用: macOS 12+ (Intel/Apple Silicon)"
    echo "  作者: iOS 开发团队"
    echo
    
    # 检查权限（避免意外使用 sudo）
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用 sudo 运行此脚本"
        exit 1
    fi
    
    # 设置错误处理
    trap handle_error ERR
    
    # 检查项目目录
    check_project_directory
    
    # 显示系统信息
    log_info "系统信息:"
    log_info "  macOS: $(sw_vers -productVersion)"
    log_info "  架构: $(uname -m)"
    log_info "  Shell: $SHELL"
    echo
    
    # 逐步检查和配置
    check_xcode_tools
    echo
    check_homebrew
    echo
    check_rbenv
    echo
    manage_ruby_versions
    echo
    check_bundler
    echo
    check_swift
    echo
    check_fastlane
    echo
    
    # 显示配置总结
    show_environment_summary
}

# 检查参数
case "${1:-}" in
    --help|-h)
        echo "macOS iOS 开发环境一键配置脚本"
        echo
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  --help, -h     显示此帮助信息"
        echo "  --version, -v  显示版本信息"
        echo
        echo "功能:"
        echo "  • 自动检查和安装 Xcode Command Line Tools"
        echo "  • 自动检查和安装 Homebrew"
        echo "  • 自动检查和安装 rbenv + Ruby 3.2.8"
        echo "  • 自动配置 Bundler 和 Fastlane"
        echo "  • 智能处理多版本 Ruby 环境"
        echo "  • 自动清理和修复常见问题"
        echo
        exit 0
        ;;
    --version|-v)
        echo "1.0.0"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac