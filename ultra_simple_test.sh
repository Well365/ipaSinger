#!/bin/bash

# 更简单的重签名测试 - 跳过provisioning profile

echo "🚀 超简化测试 - 直接使用resign"
echo "=============================="
echo ""

# 参数设置
IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"

echo "📋 测试参数:"
echo "IPA: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Sign Identity: $SIGN_IDENTITY"
echo ""

# 检查文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在"
    exit 1
fi

echo "✅ IPA文件存在"
echo ""

# 进入fastlane目录
cd fastlane

# 创建输出目录
mkdir -p ./out

# 设置环境变量
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

# 直接测试resign action
echo "✍️  测试: 直接使用resign action"
echo "============================="

echo "尝试1: 不指定provisioning profile (自动匹配)"
echo "bundle exec fastlane resign ipa:\"$IPA_PATH\" signing_identity:\"$SIGN_IDENTITY\" output:\"./out/test-resigned.ipa\""

bundle exec fastlane resign \
  ipa:"$IPA_PATH" \
  signing_identity:"$SIGN_IDENTITY" \
  output:"./out/test-resigned.ipa"

result1=$?
echo "结果1: $result1"
echo ""

if [ $result1 -eq 0 ]; then
    echo "✅ 方法1成功!"
    ls -la ./out/
else
    echo "⚠️  方法1失败，尝试方法2..."
    echo ""
    
    echo "尝试2: 使用codesign直接重签名"
    echo "============================"
    
    # 解压IPA
    TEMP_DIR="/tmp/resign_test_$$"
    mkdir -p "$TEMP_DIR"
    
    echo "解压IPA到 $TEMP_DIR"
    cd "$TEMP_DIR"
    unzip -q "$IPA_PATH"
    
    if [ -d "Payload" ]; then
        APP_PATH=$(find Payload -name "*.app" | head -1)
        echo "找到app路径: $APP_PATH"
        
        echo "当前签名信息:"
        codesign -dv "$APP_PATH" 2>&1 | head -5
        echo ""
        
        echo "尝试重新签名:"
        codesign --force --sign "$SIGN_IDENTITY" "$APP_PATH"
        
        if [ $? -eq 0 ]; then
            echo "✅ 重签名成功"
            
            echo "验证签名:"
            codesign -dv "$APP_PATH" 2>&1 | head -5
            
            echo ""
            echo "重新打包IPA..."
            cd "$TEMP_DIR"
            zip -r "/Users/maxwell/Documents/idears/ipaSingerMac/fastlane/out/manual-resigned.ipa" Payload/
            
            if [ $? -eq 0 ]; then
                echo "✅ 重新打包成功"
                echo "输出文件: /Users/maxwell/Documents/idears/ipaSingerMac/fastlane/out/manual-resigned.ipa"
            else
                echo "❌ 重新打包失败"
            fi
        else
            echo "❌ 重签名失败"
        fi
    else
        echo "❌ 未找到Payload目录"
    fi
    
    # 清理
    rm -rf "$TEMP_DIR"
fi

echo ""
echo "📊 测试完成"
echo "==========="
echo "查看输出文件:"
ls -la ./out/ 2>/dev/null || echo "无输出文件"