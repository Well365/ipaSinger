#!/bin/bash

echo "🔧 FastLane 证书修复测试"
echo "======================"
echo

echo "📝 设置测试环境变量..."

# 基本参数 - 根据之前的配置
export IPA_PATH="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
export BUNDLE_ID="happy.foxglobal.com585471"
export UDID="00008120-001A10513622201E"
export SIGN_IDENTITY="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"

# FastLane 配置
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export FASTLANE_DISABLE_COLORS="1"
export FASTLANE_SKIP_UPDATE_CHECK="1"
export FASTLANE_OPT_OUT_USAGE="1"

echo "✅ 环境变量设置完成："
echo "IPA_PATH=$IPA_PATH"
echo "BUNDLE_ID=$BUNDLE_ID"
echo "UDID=$UDID"
echo

# 检查 IPA 文件
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA文件不存在: $IPA_PATH"
    echo "请确认文件路径正确"
    echo
    echo "💡 您可以："
    echo "1. 将任意 IPA 文件复制到该路径"
    echo "2. 修改 IPA_PATH 变量指向现有文件"
    echo "3. 或者先跳过此测试，直接使用 Apple Developer API 方案"
    echo
    read -p "是否继续测试（即使IPA文件不存在）？(y/n): " continue_test
    if [ "$continue_test" != "y" ]; then
        echo "退出测试。建议使用 Apple Developer API 方案。"
        exit 1
    fi
fi

# 检查 Apple ID 凭证
if [ -z "$FASTLANE_USER" ] || [ -z "$FASTLANE_PASSWORD" ]; then
    echo "⚠️  需要设置 Apple ID 凭证"
    read -p "Apple ID: " apple_id
    echo "应用专用密码:"
    read -s app_password
    echo
    
    export FASTLANE_USER="$apple_id"
    export FASTLANE_PASSWORD="$app_password"
fi

echo "🧪 开始测试修复后的 FastLane..."
echo "=============================="
echo

# 进入 fastlane 目录
cd fastlane || {
    echo "❌ 无法进入 fastlane 目录"
    exit 1
}

echo "📋 执行步骤："
echo "1. 登录验证"
echo "2. 证书查询（测试修复）"
echo "3. Provisioning Profile 创建"
echo "4. IPA 重签名"
echo

echo "🚀 开始执行..."
bundle exec fastlane resign_ipa

resign_result=$?

echo
echo "📊 测试结果分析："
echo "=================="

if [ $resign_result -eq 0 ]; then
    echo "✅ FastLane 修复成功！"
    echo
    echo "🎉 证书类型修复有效："
    echo "• 证书查询问题已解决"
    echo "• Provisioning Profile 创建成功"
    echo "• IPA 重签名完成"
    echo
    echo "📁 检查输出文件："
    if [ -d "./out" ]; then
        echo "输出目录内容:"
        ls -la ./out/
        echo
        
        resigned_files=$(find ./out -name "*resigned*.ipa" -o -name "*signed*.ipa")
        if [ -n "$resigned_files" ]; then
            echo "✅ 找到重签名的IPA文件:"
            echo "$resigned_files" | while read file; do
                echo "  📱 $(basename "$file")"
                echo "     大小: $(ls -lh "$file" | awk '{print $5}')"
                echo "     路径: $file"
            done
        else
            echo "⚠️  未找到重签名的IPA文件，但流程执行成功"
        fi
    else
        echo "⚠️  未找到输出目录"
    fi
    
    echo
    echo "🎯 FastLane 方案现在可以工作了！"
    echo "但仍然推荐使用 Apple Developer API 方案获得更好的体验。"

else
    echo "❌ FastLane 仍然失败"
    echo
    echo "📋 可能的原因："
    echo "• 证书不存在或已过期"
    echo "• 开发者账号权限不足"
    echo "• 网络连接问题"
    echo "• Apple 服务器问题"
    echo "• 其他 FastLane 内部问题"
    echo
    echo "💡 建议的解决方案："
    echo "1. 检查开发者账号中是否有有效的 iOS Development 证书"
    echo "2. 如果没有，手动创建一个开发证书"
    echo "3. 或者直接使用 Apple Developer API 方案，避免这些复杂性"
    echo
    echo "🚀 Apple Developer API 方案的优势再次体现："
    echo "• 无需依赖复杂的第三方工具"
    echo "• 更直接的错误诊断和处理"
    echo "• 更好的可维护性和扩展性"
fi

echo
echo "📈 技术方案对比总结："
echo "===================="
echo
echo "FastLane 方案："
echo "  优点: ✅ 社区支持，功能丰富"
echo "  缺点: ❌ 配置复杂，调试困难，依赖性强，错误处理不透明"
echo
echo "Apple Developer API 方案："
echo "  优点: ✅ 官方支持，原生实现，错误透明，易于维护，完全可控"
echo "  缺点: ❌ 需要实现更多细节（但我们已经完成了！）"
echo
echo "结论: Apple Developer API 方案仍然是更优选择！"