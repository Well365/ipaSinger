# Ruby 环境配置指南# Ruby 环境配置指南



本文档记录了 macOS 平台上 Ruby 环境的配置过程，特别针对 Swift 项目中 Fastlane 工具链的依赖配置。本文档记录了 macOS 平台上 Ruby 环境的配置过程，特别针对 Swift 项目中 Fastlane 工具链的依赖配置。



## 问题背景## 问题背景



在配置 iOS 签名工具项目时遇到的主要问题：在配置 iOS 签名工具项目时遇到的主要问题：



### 1. Swift 构建缓存问题### 1. Swift 构建缓存问题



```bash```bash

<unknown>:0: error: PCH was compiled with module cache path '~/Documents/idears/ipaSinger/.build/arm64-apple-macosx/debug/ModuleCache/3LULTCZQZ8U1F', but the path is currently '~/Documents/idears/ipaSingerMac/.build/arm64-apple-macosx/debug/ModuleCache/3LULTCZQZ8U1F'<unknown>:0: error: PCH was compiled with module cache path '~/Documents/idears/ipaSinger/.build/arm64-apple-macosx/debug/ModuleCache/3LULTCZQZ8U1F', but the path is currently '~/Documents/idears/ipaSingerMac/.build/arm64-apple-macosx/debug/ModuleCache/3LULTCZQZ8U1F'

<unknown>:0: error: missing required module 'SwiftShims'<unknown>:0: error: missing required module 'SwiftShims'

``````



**原因**：项目路径发生变化，但 Swift 构建缓存仍指向旧路径。**原因**：项目路径发生变化，但 Swift 构建缓存仍指向旧路径。



### 2. Ruby 版本兼容性问题### 2. Ruby 版本兼容性问题

```bash

```bashERROR: Error installing bundler:

ERROR: Error installing bundler:    The last version of bundler (>= 0) to support your Ruby & RubyGems was 2.4.22. 

    The last version of bundler (>= 0) to support your Ruby & RubyGems was 2.4.22.     Try installing it with `gem install bundler -v 2.4.22`

    Try installing it with `gem install bundler -v 2.4.22`    bundler requires Ruby version >= 3.2.0. The current ruby version is 2.7.6.219.

    bundler requires Ruby version >= 3.2.0. The current ruby version is 2.7.6.219.```

```

**原因**：系统默认 Ruby 版本 2.7.6 与最新 Bundler 2.7.2 不兼容。

**原因**：系统默认 Ruby 版本 2.7.6 与最新 Bundler 2.7.2 不兼容。

## 解决方案

## 解决方案

### 步骤 1: 解决 Swift 构建问题

### 步骤 1: 解决 Swift 构建问题

```bash

```bash# 清理构建缓存

# 清理构建缓存cd ~/Documents/idears/ipaSingerMac

cd ~/Documents/idears/ipaSingerMacrm -rf .build

rm -rf .buildswift package clean

swift package clean```

```

**说明**：删除所有缓存的预编译头文件和模块缓存，强制 Swift 重新构建。

**说明**：删除所有缓存的预编译头文件和模块缓存，强制 Swift 重新构建。

### 步骤 2: 安装兼容的 Bundler 版本（临时解决方案）

### 步骤 2: 安装兼容的 Bundler 版本（临时解决方案）

```bash

```bash# 安装与 Ruby 2.7.6 兼容的 Bundler 版本

# 安装与 Ruby 2.7.6 兼容的 Bundler 版本gem install bundler -v 2.4.22

gem install bundler -v 2.4.22```

```

**验证**：

**验证**：```bash

bundler --version

```bash# 输出：Bundler version 2.4.22

bundler --version```

# 输出：Bundler version 2.4.22

```### 步骤 3: 配置 Fastlane 本地环境



### 步骤 3: 配置 Fastlane 本地环境```bash

# 进入 fastlane 目录

```bashcd ~/Documents/idears/ipaSingerMac/fastlane

# 进入 fastlane 目录

cd ~/Documents/idears/ipaSingerMac/fastlane# 本地安装 gems（避免权限问题）

bundle install --path vendor/bundle

# 本地安装 gems（避免权限问题）```

bundle install --path vendor/bundle

```**验证 Fastlane 安装**：

```bash

**验证 Fastlane 安装**：bundle exec fastlane --version

# 输出：fastlane 2.228.0

```bash```

bundle exec fastlane --version

# 输出：fastlane 2.228.0### 步骤 4: 升级到 Ruby 3.2.8（推荐的长期解决方案）

```

#### 4.1 检查 rbenv 环境

### 步骤 4: 升级到 Ruby 3.2.8（推荐的长期解决方案）```bash

# 检查 rbenv 是否安装

#### 4.1 检查 rbenv 环境which rbenv

# 输出：/opt/homebrew/bin/rbenv

```bash

# 检查 rbenv 是否安装# 查看可用的 Ruby 版本

which rbenvrbenv install --list | grep "3\."

# 输出：/opt/homebrew/bin/rbenv```



# 查看可用的 Ruby 版本#### 4.2 安装 Ruby 3.2.8

rbenv install --list | grep "3\."```bash

```# 安装 Ruby 3.2.8（这个过程需要 5-10 分钟）

rbenv install 3.2.8

#### 4.2 安装 Ruby 3.2.8```



```bash**安装过程详细日志**：

# 安装 Ruby 3.2.8（这个过程需要 5-10 分钟）```

rbenv install 3.2.8ruby-build: using openssl@3 from homebrew

```==> Downloading ruby-3.2.8.tar.gz...

-> curl -q -fL -o ruby-3.2.8.tar.gz https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.8.tar.gz

**安装过程详细日志**：==> Installing ruby-3.2.8...

ruby-build: using readline from homebrew

```textruby-build: using libyaml from homebrew  

ruby-build: using openssl@3 from homebrewruby-build: using gmp from homebrew

==> Downloading ruby-3.2.8.tar.gz...-> ./configure --prefix=$HOME/.rbenv/versions/3.2.8 [配置选项...]

-> curl -q -fL -o ruby-3.2.8.tar.gz https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.8.tar.gz-> make -j 8

==> Installing ruby-3.2.8...-> make install

ruby-build: using readline from homebrew==> Installed ruby-3.2.8 to ~/.rbenv/versions/3.2.8

ruby-build: using libyaml from homebrew  ```

ruby-build: using gmp from homebrew

-> ./configure --prefix=$HOME/.rbenv/versions/3.2.8 [配置选项...]#### 4.3 配置项目使用新的 Ruby 版本

-> make -j 8```bash

-> make install# 创建项目级 Ruby 版本文件

==> Installed ruby-3.2.8 to ~/.rbenv/versions/3.2.8echo "3.2.8" > .ruby-version

```

# 设置全局 Ruby 版本（可选）

#### 4.3 配置项目使用新的 Ruby 版本rbenv global 3.2.8



```bash# 刷新 rbenv

# 创建项目级 Ruby 版本文件rbenv rehash

echo "3.2.8" > .ruby-version```



# 设置全局 Ruby 版本（可选）#### 4.4 验证 Ruby 版本

rbenv global 3.2.8```bash

# 查看所有已安装的版本

# 刷新 rbenvrbenv versions

rbenv rehash# 输出：

```#   system

# * 3.2.8 (set by ~/Documents/idears/ipaSingerMac/.ruby-version)

#### 4.4 验证 Ruby 版本

# 验证当前 Ruby 版本

```bashruby --version

# 查看所有已安装的版本# 输出：ruby 3.2.8p91 (2025-xx-xx revision xxxxxx) [arm64-darwin23]

rbenv versions```

# 输出：

#   system## 最终环境配置

# * 3.2.8 (set by ~/Documents/idears/ipaSingerMac/.ruby-version)

### 目录结构

# 验证当前 Ruby 版本```

ruby --version~/Documents/idears/ipaSingerMac/

# 输出：ruby 3.2.8p91 (2025-xx-xx revision xxxxxx) [arm64-darwin23]├── .ruby-version          # 指定项目使用 Ruby 3.2.8

```├── Package.swift          # Swift 包配置

├── Sources/               # Swift 源码

## 最终环境配置├── fastlane/             

│   ├── Gemfile           # Ruby 依赖配置

### 目录结构│   ├── Fastfile          # Fastlane 配置

│   └── vendor/           # 本地 gem 安装目录

```text│       └── bundle/

~/Documents/idears/ipaSingerMac/└── .build/               # Swift 构建目录（已清理）

├── .ruby-version          # 指定项目使用 Ruby 3.2.8```

├── Package.swift          # Swift 包配置

├── Sources/               # Swift 源码### 环境变量检查

├── fastlane/             ```bash

│   ├── Gemfile           # Ruby 依赖配置# 验证 Ruby 环境

│   ├── Fastfile          # Fastlane 配置ruby --version              # Ruby 3.2.8

│   └── vendor/           # 本地 gem 安装目录bundler --version           # Bundler 2.4.22（或新版本）

│       └── bundle/rbenv --version             # rbenv 版本信息

└── .build/               # Swift 构建目录（已清理）

```# 验证 Fastlane

cd fastlane

### 环境变量检查bundle exec fastlane --version  # fastlane 2.228.0

```

```bash

# 验证 Ruby 环境## 常用命令参考

ruby --version              # Ruby 3.2.8

bundler --version           # Bundler 2.4.22（或新版本）### Ruby 版本管理

rbenv --version             # rbenv 版本信息```bash

# 列出可安装的 Ruby 版本

# 验证 Fastlanerbenv install --list

cd fastlane

bundle exec fastlane --version  # fastlane 2.228.0# 安装特定版本

```rbenv install 3.2.8



## 常用命令参考# 查看已安装版本

rbenv versions

### Ruby 版本管理

# 设置全局版本

```bashrbenv global 3.2.8

# 列出可安装的 Ruby 版本

rbenv install --list# 设置项目版本

rbenv local 3.2.8

# 安装特定版本

rbenv install 3.2.8# 刷新 rbenv

rbenv rehash

# 查看已安装版本```

rbenv versions

### Bundler 和 Gem 管理

# 设置全局版本```bash

rbenv global 3.2.8# 安装特定版本的 bundler

gem install bundler -v 2.4.22

# 设置项目版本

rbenv local 3.2.8# 本地安装 gems

bundle install --path vendor/bundle

# 刷新 rbenv

rbenv rehash# 配置本地路径（推荐方式）

```bundle config set --local path 'vendor/bundle'

bundle install

### Bundler 和 Gem 管理

# 执行 Fastlane 命令

```bashbundle exec fastlane [命令]

# 安装特定版本的 bundler```

gem install bundler -v 2.4.22

### Swift 项目管理

# 本地安装 gems```bash

bundle install --path vendor/bundle# 清理构建缓存

swift package clean

# 配置本地路径（推荐方式）rm -rf .build

bundle config set --local path 'vendor/bundle'

bundle install# 解析依赖

swift package resolve

# 执行 Fastlane 命令

bundle exec fastlane [命令]# 构建项目

```swift build



### Swift 项目管理# 运行项目

swift run

```bash```

# 清理构建缓存

swift package clean## 故障排除

rm -rf .build

### 问题 1: Ruby 版本切换不生效

# 解析依赖```bash

swift package resolve# 确保 rbenv 已正确初始化

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc

# 构建项目echo 'eval "$(rbenv init -)"' >> ~/.zshrc

swift buildsource ~/.zshrc

```

# 运行项目

swift run### 问题 2: Bundle 找不到 gems

``````bash

# 重新安装到本地目录

## 故障排除cd fastlane

rm -rf vendor/bundle

### 问题 1: Ruby 版本切换不生效bundle install --path vendor/bundle

```

```bash

# 确保 rbenv 已正确初始化### 问题 3: Swift 构建仍然失败

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc```bash

echo 'eval "$(rbenv init -)"' >> ~/.zshrc# 完全清理构建环境

source ~/.zshrcrm -rf .build

```rm -rf Package.resolved

swift package clean

### 问题 2: Bundle 找不到 gemsswift package resolve

swift build

```bash```

# 重新安装到本地目录

cd fastlane## 总结

rm -rf vendor/bundle

bundle install --path vendor/bundle通过以上配置，我们实现了：

```

1. ✅ **Swift 项目正常构建**：清理缓存解决路径不匹配问题

### 问题 3: Swift 构建仍然失败2. ✅ **Ruby 环境升级**：从 2.7.6 升级到 3.2.8

3. ✅ **Fastlane 正常工作**：兼容的 Bundler 版本和本地 gem 安装

```bash4. ✅ **版本管理规范**：使用 rbenv 管理 Ruby 版本，.ruby-version 文件指定项目版本

# 完全清理构建环境

rm -rf .build这个配置为 iOS 应用签名和分发流程提供了稳定的开发环境基础。

rm -rf Package.resolved

swift package clean---

swift package resolve

swift build**创建时间**: 2025年10月26日  

```**适用系统**: macOS (Apple Silicon)  

**相关工具**: rbenv, Ruby, Bundler, Swift, Fastlane
## 总结

通过以上配置，我们实现了：

1. ✅ **Swift 项目正常构建**：清理缓存解决路径不匹配问题
2. ✅ **Ruby 环境升级**：从 2.7.6 升级到 3.2.8
3. ✅ **Fastlane 正常工作**：兼容的 Bundler 版本和本地 gem 安装
4. ✅ **版本管理规范**：使用 rbenv 管理 Ruby 版本，.ruby-version 文件指定项目版本

这个配置为 iOS 应用签名和分发流程提供了稳定的开发环境基础。

---

**创建时间**: 2025年10月26日  
**适用系统**: macOS (Apple Silicon)  
**相关工具**: rbenv, Ruby, Bundler, Swift, Fastlane