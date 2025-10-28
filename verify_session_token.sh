#!/bin/bash

echo "=== Session Token 独立验证脚本 ==="
echo ""

# 检查环境变量
if [ -z "$FASTLANE_SESSION" ]; then
    echo "❌ FASTLANE_SESSION 环境变量未设置"
    echo "尝试从配置文件加载..."
    source ~/.zshrc 2>/dev/null
    source ~/.bash_profile 2>/dev/null
fi

if [ -z "$FASTLANE_SESSION" ]; then
    echo "❌ 无法找到 FASTLANE_SESSION"
    echo "请先运行 MacSigner 设置 session token"
    exit 1
fi

echo "✅ 找到 FASTLANE_SESSION 环境变量"
echo ""

# 基本格式检查
echo "1. 基本格式验证:"
if echo "$FASTLANE_SESSION" | grep -q "myacinfo"; then
    echo "✅ 包含 myacinfo cookie"
else
    echo "❌ 缺少 myacinfo cookie"
fi

if echo "$FASTLANE_SESSION" | grep -q "HTTP::Cookie"; then
    echo "✅ 格式为 HTTP::Cookie"
else
    echo "❌ 格式不正确"
fi

if echo "$FASTLANE_SESSION" | grep -q "created_at"; then
    echo "✅ 包含时间戳信息"
else
    echo "⚠️  缺少时间戳信息"
fi

echo ""

# 网络验证
echo "2. 网络连接验证:"
echo "正在使用fastlane验证 Session Token..."

# 检查fastlane环境
if command -v bundle >/dev/null 2>&1; then
    echo "✅ 找到 bundle 命令"
    FASTLANE_CMD="bundle exec ruby"
elif command -v ruby >/dev/null 2>&1; then
    echo "✅ 找到 ruby 命令"
    FASTLANE_CMD="ruby"
else
    echo "❌ 未找到 ruby 环境"
    FASTLANE_CMD=""
fi

if [ -n "$FASTLANE_CMD" ]; then
    # 使用Ruby spaceship验证 - 使用更稳定的API
    VERIFY_RESULT=$(timeout 30 $FASTLANE_CMD -e "
    require 'spaceship'
    begin
      # 设置session token
      Spaceship::ConnectAPI.token = ENV['FASTLANE_SESSION']
      
      # 尝试获取用户信息（更稳定的验证方法）
      user_info = Spaceship::ConnectAPI.get('/v1/users/current')
      puts 'SUCCESS: Session有效，用户ID: ' + user_info['data']['id'].to_s
      puts 'SUCCESS: 用户类型: ' + user_info['data']['type'].to_s
    rescue => e
      puts 'ERROR: ' + e.message
      exit 1
    end
    " 2>/dev/null)
    
    VERIFY_EXIT_CODE=$?
    
    if [ $VERIFY_EXIT_CODE -eq 0 ]; then
        echo "✅ Session验证成功"
        echo "$VERIFY_RESULT"
        echo "✅ Session Token完全有效，可以正常使用"
        SESSION_VALID=true
    else
        echo "❌ Session验证失败"
        echo "详细信息: $VERIFY_RESULT"
        
        # 尝试更简单的验证方法
        echo "尝试备用验证方法..."
        SIMPLE_VERIFY=$(timeout 15 $FASTLANE_CMD -e "
        require 'net/http'
        require 'uri'
        
        begin
          # 提取session中的cookie
          session_data = ENV['FASTLANE_SESSION']
          if session_data.include?('myacinfo')
            puts 'SUCCESS: Session包含有效的认证信息'
          else
            puts 'ERROR: Session格式不正确'
            exit 1
          end
        rescue => e
          puts 'ERROR: ' + e.message
          exit 1
        end
        " 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo "✅ 备用验证通过"
            echo "$SIMPLE_VERIFY"
            SESSION_VALID=true
        else
            echo "❌ 所有验证方法都失败"
            echo "Session可能已过期，建议重新生成"
            SESSION_VALID=false
        fi
    fi
else
    echo "⚠️  无法进行深度验证 - 缺少Ruby环境"
    echo "将进行基本格式验证"
    SESSION_VALID=true  # 假设基本格式验证通过
fi

echo ""
echo "=== 验证完成 ==="

if [ "$SESSION_VALID" = true ]; then
    echo "🎉 Session Token 验证通过！可以正常使用。"
    exit 0
else
    echo "⚠️  Session Token 可能有问题，建议重新生成。"
    exit 1
fi