# macOS iOS 开发环境完整配置指南

本文档提供了从零开始在 macOS 上配置 iOS 开发环境的完整指南，包括 Xcode、Homebrew、Ruby、Swift 和 Fastlane 等工具链的安装和配置。

## 🚀 快速开始 - 一键检查脚本

### 使用方法

```bash
# 下载并运行一键检查脚本
curl -fsSL https://raw.githubusercontent.com/Well365/ipaSinger/main/scripts/01_setup_check.sh | bash
```

或者手动创建脚本文件：

```bash
# 创建脚本文件
cat > 01_setup_check.sh << 'EOF'
#!/bin/bash

# macOS iOS 开发环境一键检查和配置脚本
# 适用于 macOS (Intel/Apple Silicon)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 检查并安装 Xcode Command Line Tools
check_xcode_tools() {
    log_info "检查 Xcode Command Line Tools..."
    
    if xcode-select --print-path &>/dev/null; then
        log_success "Xcode Command Line Tools 已安装"
        log_info "路径: $(xcode-select --print-path)"
    else
        log_warning "Xcode Command Line Tools 未安装，开始安装..."
        xcode-select --install
        log_info "请在弹出的对话框中完成安装，然后重新运行此脚本"
        exit 1
    fi
}

# 检查并安装 Homebrew
check_homebrew() {
    log_info "检查 Homebrew..."
    
    if command -v brew &>/dev/null; then
        log_success "Homebrew 已安装"
        brew_version=$(brew --version | head -n1)
        log_info "版本: $brew_version"
        
        log_info "更新 Homebrew..."
        brew update || log_warning "Homebrew 更新失败，继续执行"
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
    log_info "检查 rbenv..."
    
    if command -v rbenv &>/dev/null; then
        log_success "rbenv 已安装"
        rbenv_version=$(rbenv --version)
        log_info "版本: $rbenv_version"
    else
        log_warning "rbenv 未安装，开始安装..."
        brew install rbenv ruby-build
        
        # 添加到 shell 配置
        if ! grep -q 'rbenv init' ~/.zshrc 2>/dev/null; then
            echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
            echo 'eval "$(rbenv init -)"' >> ~/.zshrc
        fi
        
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        
        log_success "rbenv 安装完成"
    fi
}

# 检查并安装 Ruby 3.2.8
check_ruby() {
    log_info "检查 Ruby 环境..."
    
    # 检查 Ruby 3.2.8 是否已安装
    if rbenv versions | grep -q "3.2.8"; then
        log_success "Ruby 3.2.8 已安装"
    else
        log_warning "Ruby 3.2.8 未安装，开始安装..."
        log_info "这个过程可能需要 5-10 分钟，请耐心等待..."
        
        rbenv install 3.2.8
        log_success "Ruby 3.2.8 安装完成"
    fi
    
    # 设置项目 Ruby 版本
    if [[ -f ".ruby-version" ]]; then
        current_version=$(cat .ruby-version)
        if [[ "$current_version" == "3.2.8" ]]; then
            log_success "项目 Ruby 版本已设置为 3.2.8"
        else
            log_info "更新项目 Ruby 版本到 3.2.8"
            echo "3.2.8" > .ruby-version
        fi
    else
        log_info "创建 .ruby-version 文件"
        echo "3.2.8" > .ruby-version
    fi
    
    # 刷新 rbenv
    rbenv rehash
    
    # 检查当前 Ruby 版本
    current_ruby=$(ruby --version)
    log_info "当前 Ruby 版本: $current_ruby"
}

# 检查并安装 Bundler
check_bundler() {
    log_info "检查 Bundler..."
    
    if command -v bundler &>/dev/null; then
        bundler_version=$(bundler --version)
        log_success "Bundler 已安装: $bundler_version"
    else
        log_warning "Bundler 未安装，开始安装兼容版本..."
        gem install bundler -v 2.4.22
        log_success "Bundler 2.4.22 安装完成"
    fi
}

# 检查并配置 Fastlane
check_fastlane() {
    log_info "检查 Fastlane 环境..."
    
    if [[ -d "fastlane" ]]; then
        cd fastlane
        
        if [[ -f "Gemfile" ]]; then
            log_info "检查 Fastlane gems..."
            
            # 配置本地 bundle 路径
            if [[ ! -f ".bundle/config" ]]; then
                bundle config set --local path 'vendor/bundle'
            fi
            
            # 安装 gems
            log_info "安装 Fastlane 依赖..."
            bundle install
            
            # 验证 Fastlane
            if bundle exec fastlane --version &>/dev/null; then
                fastlane_version=$(bundle exec fastlane --version | grep "fastlane" | head -n1)
                log_success "Fastlane 配置成功: $fastlane_version"
            else
                log_error "Fastlane 配置失败"
                return 1
            fi
        else
            log_warning "未找到 Gemfile，跳过 Fastlane 配置"
        fi
        
        cd ..
    else
        log_warning "未找到 fastlane 目录，跳过 Fastlane 配置"
    fi
}

# 检查 Swift 环境
check_swift() {
    log_info "检查 Swift 环境..."
    
    if command -v swift &>/dev/null; then
        swift_version=$(swift --version | head -n1)
        log_success "Swift 已安装: $swift_version"
        
        # 清理可能的构建缓存问题
        if [[ -d ".build" ]]; then
            log_info "清理旧的构建缓存..."
            rm -rf .build
            swift package clean
            log_success "构建缓存已清理"
        fi
        
        # 检查项目依赖
        if [[ -f "Package.swift" ]]; then
            log_info "解析项目依赖..."
            swift package resolve
            log_success "项目依赖解析完成"
        fi
    else
        log_error "Swift 未安装，请安装 Xcode"
        return 1
    fi
}

# 环境检查总结
show_summary() {
    log_info "环境检查完成，以下是当前配置："
    echo
    echo "🔧 开发工具："
    echo "  Xcode Tools: $(xcode-select --print-path)"
    echo "  Homebrew: $(brew --version | head -n1)"
    echo "  Swift: $(swift --version | head -n1)"
    echo
    echo "💎 Ruby 环境："
    echo "  rbenv: $(rbenv --version)"
    echo "  Ruby: $(ruby --version)"
    echo "  Bundler: $(bundler --version)"
    echo
    if [[ -d "fastlane" ]]; then
        echo "🚀 Fastlane："
        cd fastlane
        if bundle exec fastlane --version &>/dev/null; then
            echo "  $(bundle exec fastlane --version | grep "fastlane" | head -n1)"
        else
            echo "  未配置"
        fi
        cd ..
    fi
    echo
    log_success "环境配置完成！你现在可以开始开发 iOS 应用了。"
}

# 主函数
main() {
    echo "🍎 macOS iOS 开发环境配置脚本"
    echo "=================================="
    echo
    
    # 检查 macOS 版本
    macos_version=$(sw_vers -productVersion)
    log_info "macOS 版本: $macos_version"
    
    # 检查架构
    architecture=$(uname -m)
    log_info "系统架构: $architecture"
    echo
    
    # 逐步检查和安装
    check_xcode_tools
    check_homebrew
    check_rbenv
    check_ruby
    check_bundler
    check_swift
    check_fastlane
    
    echo
    show_summary
}

# 运行主函数
main "$@"
EOF

# 使脚本可执行
chmod +x 01_setup_check.sh

# 运行脚本
./01_setup_check.sh
```

## 📋 手动安装步骤

如果你prefer手动安装，以下是详细步骤：

### 1. 安装 Xcode Command Line Tools

```bash
# 检查是否已安装
xcode-select --print-path

# 如果未安装，执行以下命令
xcode-select --install
```

### 2. 安装 Homebrew

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 添加到 PATH (Apple Silicon Mac)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 添加到 PATH (Intel Mac)
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

### 3. 安装和配置 rbenv

```bash
# 安装 rbenv
brew install rbenv ruby-build

# 添加到 shell 配置
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc

# 重新加载配置
source ~/.zshrc
```

### 4. 安装 Ruby 3.2.8

```bash
# 查看可用版本
rbenv install --list | grep 3.2

# 安装 Ruby 3.2.8
rbenv install 3.2.8

# 设置项目 Ruby 版本
echo "3.2.8" > .ruby-version

# 刷新 rbenv
rbenv rehash

# 验证版本
ruby --version
```

### 5. 安装 Bundler 和配置 Fastlane

```bash
# 安装兼容的 Bundler 版本
gem install bundler -v 2.4.22

# 进入 fastlane 目录
cd fastlane

# 配置本地 bundle 安装路径
bundle config set --local path 'vendor/bundle'

# 安装依赖
bundle install

# 验证 Fastlane
bundle exec fastlane --version
```

### 6. Swift 项目配置

```bash
# 清理可能的缓存问题
rm -rf .build
swift package clean

# 解析依赖
swift package resolve

# 构建项目
swift build
```

## 🔧 环境变量配置

将以下内容添加到你的 `~/.zshrc` 文件：

```bash
# Homebrew
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# 可选：设置 Ruby 优化
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
export LDFLAGS="-L$(brew --prefix openssl@3)/lib"
export CPPFLAGS="-I$(brew --prefix openssl@3)/include"
```

## 🐛 常见问题解决

### 问题 1: Ruby 版本切换不生效

```bash
# 检查 rbenv 是否正确初始化
which ruby
which rbenv

# 重新初始化 rbenv
eval "$(rbenv init -)"
rbenv rehash

# 检查项目目录是否有 .ruby-version 文件
cat .ruby-version
```

### 问题 2: Bundler 安装失败

```bash
# 清理 gem 缓存
gem cleanup

# 重新安装 bundler
gem uninstall bundler --all
gem install bundler -v 2.4.22

# 如果权限问题，使用本地安装
bundle install --path vendor/bundle
```

### 问题 3: Swift 构建缓存问题

```bash
# 完全清理构建环境
rm -rf .build
rm -rf Package.resolved
swift package clean
swift package reset

# 重新构建
swift package resolve
swift build
```

### 问题 4: Fastlane 权限问题

```bash
# 使用本地 bundle 配置
cd fastlane
bundle config set --local path 'vendor/bundle'
bundle install

# 如果仍有问题，尝试清理重装
rm -rf vendor/bundle
rm -rf .bundle
bundle install --path vendor/bundle
```

## 📱 项目特定配置

### iOS 签名项目配置

```bash
# 确保在项目根目录
cd /path/to/your/ipaSingerMac

# 设置 Ruby 版本
echo "3.2.8" > .ruby-version

# 配置 Fastlane
cd fastlane
bundle config set --local path 'vendor/bundle'
bundle install

# 验证配置
bundle exec fastlane --version
```

### 环境验证脚本

创建 `verify_environment.sh` 用于快速验证环境：

```bash
#!/bin/bash

echo "🔍 环境验证检查"
echo "==================="

echo -n "✅ Xcode Tools: "
if xcode-select --print-path &>/dev/null; then
    echo "已安装 ($(xcode-select --print-path))"
else
    echo "❌ 未安装"
fi

echo -n "✅ Homebrew: "
if command -v brew &>/dev/null; then
    echo "$(brew --version | head -n1)"
else
    echo "❌ 未安装"
fi

echo -n "✅ rbenv: "
if command -v rbenv &>/dev/null; then
    echo "$(rbenv --version)"
else
    echo "❌ 未安装"
fi

echo -n "✅ Ruby: "
if command -v ruby &>/dev/null; then
    echo "$(ruby --version)"
else
    echo "❌ 未安装"
fi

echo -n "✅ Bundler: "
if command -v bundler &>/dev/null; then
    echo "$(bundler --version)"
else
    echo "❌ 未安装"
fi

echo -n "✅ Swift: "
if command -v swift &>/dev/null; then
    echo "$(swift --version | head -n1)"
else
    echo "❌ 未安装"
fi

if [[ -d "fastlane" ]]; then
    echo -n "✅ Fastlane: "
    cd fastlane
    if bundle exec fastlane --version &>/dev/null; then
        echo "$(bundle exec fastlane --version | grep "fastlane" | head -n1)"
    else
        echo "❌ 配置有误"
    fi
    cd ..
fi

echo
echo "🎉 环境验证完成！"
```

## 📚 相关资源

- [Xcode 下载](https://developer.apple.com/xcode/)
- [Homebrew 官网](https://brew.sh/)
- [rbenv GitHub](https://github.com/rbenv/rbenv)
- [Fastlane 文档](https://docs.fastlane.tools/)
- [Swift 官方文档](https://swift.org/documentation/)

---

**创建时间**: 2025年10月26日  
**适用系统**: macOS 12+ (Intel/Apple Silicon)  
**维护者**: iOS 开发团队