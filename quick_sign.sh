#!/bin/bash

echo "⚡ 快速 IPA 签名工具"
echo "==================="
echo "使用 FastLane 下载的 mobileprovision 文件直接签名 IPA"
echo

# 默认配置
IPA_PATH="${1:-/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa}"
BUNDLE_ID="${2:-exam.duo.apih}"
PROVISION_DIR="./out"
OUTPUT_DIR="./signed"

echo "🎯 快速签名模式"
echo "IPA: $(basename "$IPA_PATH")"
echo "Bundle ID: $BUNDLE_ID"
echo

# 快速检查
[ ! -f "$IPA_PATH" ] && echo "❌ IPA 不存在: $IPA_PATH" && exit 1

# 查找配置文件
PROVISION_FILE=$(find "$PROVISION_DIR" -name "*.mobileprovision" | head -1)
[ -z "$PROVISION_FILE" ] && echo "❌ 未找到 mobileprovision 文件" && exit 1

echo "✅ 配置文件: $(basename "$PROVISION_FILE")"

# 查找签名证书
SIGN_IDENTITY=$(security find-identity -v -p codesigning | grep "iPhone Developer" | head -1 | awk -F'"' '{print $2}')
if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY="iPhone Developer"
    echo "⚠️  使用通用签名身份: $SIGN_IDENTITY"
else
    echo "✅ 签名身份: $SIGN_IDENTITY"
fi

# 创建工作环境
WORK_DIR="$(mktemp -d)"
mkdir -p "$OUTPUT_DIR"

echo
echo "🚀 开始签名..."

# 解压 → 替换配置文件 → 签名 → 打包
cd "$WORK_DIR" && \
unzip -q "$IPA_PATH" && \
APP_PATH=$(find . -name "*.app" | head -1) && \
cp "$(dirname "$IPA_PATH")/../$PROVISION_FILE" "$APP_PATH/embedded.mobileprovision" && \
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_PATH/Info.plist" && \
rm -rf "$APP_PATH/_CodeSignature" && \
find "$APP_PATH" -name "*.framework" -exec codesign --force --sign "$SIGN_IDENTITY" {} \; && \
find "$APP_PATH" -name "*.appex" -exec codesign --force --sign "$SIGN_IDENTITY" {} \; && \
codesign --force --sign "$SIGN_IDENTITY" "$APP_PATH" && \
cd Payload && \
zip -r "$OUTPUT_DIR/$(basename "$IPA_PATH" .ipa)_resigned.ipa" . && \
cd ../..

# 检查结果
OUTPUT_IPA="$OUTPUT_DIR/$(basename "$IPA_PATH" .ipa)_resigned.ipa"
if [ -f "$OUTPUT_IPA" ]; then
    echo "✅ 签名成功！"
    echo "📁 输出: $OUTPUT_IPA"
    echo "📦 大小: $(ls -lh "$OUTPUT_IPA" | awk '{print $5}')"
    
    # 验证签名
    echo "🔍 验证签名..."
    unzip -q "$OUTPUT_IPA" -d "$WORK_DIR/verify"
    APP_VERIFY=$(find "$WORK_DIR/verify" -name "*.app" | head -1)
    codesign --verify "$APP_VERIFY" && echo "✅ 签名有效" || echo "⚠️  签名警告"
else
    echo "❌ 签名失败"
fi

# 清理
rm -rf "$WORK_DIR"

echo
echo "🎯 完成！这种混合方案的优势："
echo "• 利用 FastLane 的设备注册和配置文件下载"
echo "• 避开 FastLane 的证书管理问题" 
echo "• 使用可靠的系统 codesign 工具"
echo "• 实现了完整的签名流程"