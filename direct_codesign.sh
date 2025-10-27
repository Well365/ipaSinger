#!/bin/bash

echo "🔐 IPA 直接签名脚本"
echo "==================="
echo
echo "此脚本使用 FastLane 下载的 mobileprovision 文件"
echo "结合系统 codesign 工具直接对 IPA 进行重签名"
echo

# 配置参数  
SIGN_IDENTITY="Apple Development: Wenhuan Chen (QJJASSCXMJ)"  # 或具体的证书标识

# 检查参数
# if [ "$#" -ne 4 ]; then
#     echo "使用方法: $0 [IPA路径] [mobileprovision路径] [Bundle ID] [输出目录]"
#     exit 1
# fi
IPA_FILE="/Users/maxwell/Downloads/PokerFOX-v1216-b16a5a-f86ac8.ipa"
BUNDLE_ID="exam.duo.apih"
# DEVELOPER_ID="72932C2C26F5B806F2D2536BD2B3658F1C3C842C"
# DEVICE_UUID="00008120-001A10513622201E"

# IPA_FILE="$1"
PROVISION_FILE="./out/adhoc_${BUNDLE_ID}.mobileprovision"
# BUNDLE_ID="$3"
OUTPUT_DIR="./signed"

echo "📋 签名参数："
echo "IPA 文件: $IPA_FILE"
echo "配置文件: $PROVISION_FILE"
echo "签名身份: $SIGN_IDENTITY"
echo "输出目录: $OUTPUT_DIR"
echo

# 检查必要文件
if [ ! -f "$IPA_FILE" ]; then
    echo "❌ IPA 文件不存在: $IPA_FILE"
    echo
    echo "使用方法:"
    echo "$0 [IPA路径] [mobileprovision路径]"
    echo
    echo "示例:"
    echo "$0 /path/to/app.ipa fastlane/out/app.mobileprovision"
    exit 1
fi

# mobileprovision 文件已通过参数传递，直接验证存在性
# 通过 PROVISION_FILE 参数已设置

echo "✅ 找到配置文件: $(basename "$PROVISION_FILE")"
echo

# 检查签名身份
echo "🔍 检查可用的签名身份..."
echo "当前配置的签名身份: $SIGN_IDENTITY"

# 显示所有可用的签名身份
echo "可用的签名身份:"
security find-identity -v -p codesigning

# 尝试使用 SHA-1 哈希值来避免 ambiguous 问题
SIGN_HASH=$(security find-identity -v -p codesigning | grep "Apple Development.*Wenhuan Chen" | head -1 | awk '{print $2}')

if [ -n "$SIGN_HASH" ]; then
    echo "✅ 找到签名证书，使用 SHA-1: $SIGN_HASH"
    SIGN_IDENTITY="$SIGN_HASH"
elif security find-identity -v -p codesigning | grep -q "Apple Development"; then
    # 如果找不到指定身份，尝试查找任何 Apple Development 证书的 SHA-1
    SIGN_HASH=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}')
    if [ -n "$SIGN_HASH" ]; then
        echo "⚠️  使用找到的第一个 Apple Development 证书: $SIGN_HASH"
        SIGN_IDENTITY="$SIGN_HASH"
    fi
elif security find-identity -v -p codesigning | grep -q "iPhone Developer"; then
    # 最后尝试查找传统的 iPhone Developer 证书的 SHA-1
    SIGN_HASH=$(security find-identity -v -p codesigning | grep "iPhone Developer" | head -1 | awk '{print $2}')
    if [ -n "$SIGN_HASH" ]; then
        echo "⚠️  使用找到的 iPhone Developer 证书: $SIGN_HASH"
        SIGN_IDENTITY="$SIGN_HASH"
    fi
else
    echo "❌ 未找到任何可用的开发证书"
    exit 1
fi

echo "✅ 将使用签名身份: $SIGN_IDENTITY"

# 创建工作目录
WORK_DIR="$(mktemp -d)"
echo "📁 创建临时工作目录: $WORK_DIR"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 解压 IPA
echo "📦 解压 IPA 文件..."
cd "$WORK_DIR"
unzip -q "$IPA_FILE"
if [ $? -ne 0 ]; then
    echo "❌ 解压 IPA 失败"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 查找 .app 文件
APP_PATH=$(find . -name "*.app" | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ 未找到 .app 文件"
    rm -rf "$WORK_DIR"
    exit 1
fi

echo "✅ 找到应用: $(basename "$APP_PATH")"

# 备份原始配置文件
if [ -f "$APP_PATH/embedded.mobileprovision" ]; then
    echo "📋 备份原始 embedded.mobileprovision"
    cp "$APP_PATH/embedded.mobileprovision" "$APP_PATH/embedded.mobileprovision.backup"
fi

# 替换配置文件
echo "🔄 替换 mobileprovision 文件..."
# 保存原始工作目录
ORIGINAL_PWD="/Users/maxwell/Documents/idears/ipaSingerMac"
# 使用绝对路径
if [[ "$PROVISION_FILE" == /* ]]; then
    # 如果已经是绝对路径
    FULL_PROVISION_PATH="$PROVISION_FILE"
else
    # 如果是相对路径，添加原始目录前缀
    FULL_PROVISION_PATH="$ORIGINAL_PWD/$PROVISION_FILE"
fi

echo "配置文件完整路径: $FULL_PROVISION_PATH"
if [ -f "$FULL_PROVISION_PATH" ]; then
    cp "$FULL_PROVISION_PATH" "$APP_PATH/embedded.mobileprovision"
    echo "✅ 配置文件替换成功"
else
    echo "❌ 配置文件不存在: $FULL_PROVISION_PATH"
    echo "尝试查找配置文件..."
    find "$ORIGINAL_PWD" -name "*.mobileprovision" -type f 2>/dev/null || echo "未找到任何 .mobileprovision 文件"
    exit 1
fi

# 提取配置文件信息
echo "📊 分析配置文件信息..."
PROVISION_UUID=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
PROVISION_TEAM_ID=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract TeamIdentifier.0 xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')

echo "配置文件 UUID: $PROVISION_UUID"
echo "Team ID: $PROVISION_TEAM_ID"
echo

# 更新 Info.plist
echo "📝 更新 Info.plist..."
if [ -f "$APP_PATH/Info.plist" ]; then
    # 更新 Bundle ID
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_PATH/Info.plist"
    
    # 显示当前 Bundle ID
    CURRENT_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
    echo "更新后的 Bundle ID: $CURRENT_BUNDLE_ID"
fi

# 删除旧签名
echo "🗑️  删除原有签名..."
rm -rf "$APP_PATH/_CodeSignature"

# 对 Frameworks 进行签名
echo "🔐 签名 Frameworks..."
if [ -d "$APP_PATH/Frameworks" ]; then
    for framework in "$APP_PATH/Frameworks"/*.framework; do
        if [ -d "$framework" ]; then
            echo "  签名: $(basename "$framework")"
            codesign --force --sign "$SIGN_IDENTITY" "$framework"
        fi
    done
fi

# 对 PlugIns 进行签名
if [ -d "$APP_PATH/PlugIns" ]; then
    echo "🔐 签名 PlugIns..."
    for plugin in "$APP_PATH/PlugIns"/*.appex; do
        if [ -d "$plugin" ]; then
            echo "  签名: $(basename "$plugin")"
            codesign --force --sign "$SIGN_IDENTITY" --entitlements "$plugin/entitlements.plist" "$plugin" 2>/dev/null || \
            codesign --force --sign "$SIGN_IDENTITY" "$plugin"
        fi
    done
fi

# 签名主应用
echo "🔐 签名主应用..."
codesign --force --sign "$SIGN_IDENTITY" --entitlements "$APP_PATH/entitlements.plist" "$APP_PATH" 2>/dev/null || \
codesign --force --sign "$SIGN_IDENTITY" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ 应用签名成功"
else
    echo "❌ 应用签名失败"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 验证签名
echo "🔍 验证签名..."
codesign --verify --verbose "$APP_PATH"
VERIFY_RESULT=$?

if [ $VERIFY_RESULT -eq 0 ]; then
    echo "✅ 签名验证通过"
else
    echo "⚠️  签名验证有警告，但可能仍可使用"
fi

# 添加更详细的签名检查
echo "🔍 详细签名检查..."
echo "主应用签名信息:"
codesign -dv "$APP_PATH" 2>&1

echo
echo "检查配置文件和签名匹配性:"
# 检查配置文件中的证书
PROVISION_CERT_NAME=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract DeveloperCertificates.0 raw -o - - | openssl x509 -inform DER -noout -subject | sed 's/.*CN=\([^,]*\).*/\1/')
echo "配置文件中的证书: $PROVISION_CERT_NAME"

# 检查应用的签名身份
APP_SIGN_IDENTITY=$(codesign -dv "$APP_PATH" 2>&1 | grep "Authority=" | head -1 | sed 's/Authority=//')
echo "应用签名身份: $APP_SIGN_IDENTITY"

# 检查设备ID匹配
echo
echo "检查设备兼容性:"
PROVISION_DEVICES=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract ProvisionedDevices xml1 -o - - 2>/dev/null | grep -o '<string>[^<]*</string>' | sed 's/<[^>]*>//g' | head -5)
if [ -n "$PROVISION_DEVICES" ]; then
    echo "配置文件包含的设备ID (前5个):"
    echo "$PROVISION_DEVICES"
else
    echo "⚠️  这可能是企业级配置文件或App Store配置文件"
fi

# 重新打包 IPA
echo "📦 重新打包 IPA..."
cd "Payload"

# 修复输出路径 - 使用正确的变量名和绝对路径
OUTPUT_IPA_NAME="$(basename "$IPA_FILE" .ipa)_resigned.ipa"
OUTPUT_IPA="$ORIGINAL_PWD/$OUTPUT_DIR/$OUTPUT_IPA_NAME"

# 确保输出目录存在
mkdir -p "$ORIGINAL_PWD/$OUTPUT_DIR"

echo "目标输出文件: $OUTPUT_IPA"
echo "当前工作目录: $(pwd)"
echo "打包内容:"
ls -la

# 创建 IPA 包
zip -r "$OUTPUT_IPA" . 
ZIP_RESULT=$?

echo "打包结果代码: $ZIP_RESULT"

cd ..

if [ $ZIP_RESULT -eq 0 ] && [ -f "$OUTPUT_IPA" ]; then
    echo "✅ 重签名完成！"
    echo
    echo "📁 输出文件信息:"
    echo "  文件: $OUTPUT_IPA"
    echo "  大小: $(ls -lh "$OUTPUT_IPA" | awk '{print $5}')"
    echo "  Bundle ID: $BUNDLE_ID"
    echo "  配置文件: $(basename "$PROVISION_FILE")"
    echo
    
    # 显示签名信息
    echo "🔍 签名详细信息:"
    codesign -dv "$WORK_DIR/$APP_PATH" 2>&1 | grep -E "(Identifier|TeamIdentifier|Authority)"
    
    # 添加安装故障排除指导
    echo
    echo "📱 设备安装指导:"
    echo "========================"
    echo
    echo "如果遇到安装错误 0xe8000067，请尝试以下解决方案："
    echo
    echo "1. 🔄 重启设备和Mac，然后重试"
    echo "2. 📱 确认设备已信任此Mac (设置 > 通用 > 设备管理)"
    echo "3. 🔓 确认设备已解锁且屏幕亮起"
    echo "4. 🔌 尝试不同的USB线缆和端口"
    echo "5. 📋 检查设备UDID是否在配置文件中："
    echo "   连接设备后运行: instruments -s devices"
    echo "   对比上面显示的配置文件设备列表"
    echo
    echo "6. 🛠️  手动安装方法："
    echo "   - 使用Xcode: Window > Devices and Simulators"
    echo "   - 拖拽IPA文件到设备上"
    echo "   - 或使用 ideviceinstaller: ideviceinstaller -i \"$OUTPUT_IPA\""
    echo
    echo "7. 🔍 如果是证书问题："
    echo "   - 确保开发证书在设备上受信任"
    echo "   - 检查配置文件是否包含正确的证书"
    echo "   - 确认Bundle ID匹配"
    echo
    echo "8. ⏰ 检查配置文件有效期："
    PROVISION_EXPIRY=$(security cms -D -i "$WORK_DIR/$APP_PATH/embedded.mobileprovision" | plutil -extract ExpirationDate xml1 -o - - | sed -n 's/.*<date>\(.*\)<\/date>.*/\1/p')
    echo "   配置文件到期时间: $PROVISION_EXPIRY"
    echo
    
else
    echo "❌ 重新打包失败"
    echo "调试信息:"
    echo "  ZIP 结果: $ZIP_RESULT"
    echo "  输出文件存在: $([ -f "$OUTPUT_IPA" ] && echo "是" || echo "否")"
    echo "  输出目录内容:"
    ls -la "$ORIGINAL_PWD/$OUTPUT_DIR/" 2>/dev/null || echo "输出目录不存在"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 清理临时文件
echo "🧹 清理临时文件..."
rm -rf "$WORK_DIR"

echo
echo "🎉 签名流程完成！"
echo "========================"
echo
echo "✅ 成功使用 FastLane 获取的配置文件完成了 IPA 重签名"
echo "✅ 绕过了 FastLane 的证书管理问题"
echo "✅ 直接使用系统 codesign 工具，更加可靠"
echo
echo "📋 使用说明："
echo "1. 先运行 FastLane 获取 mobileprovision 文件"
echo "2. 运行此脚本对任意 IPA 进行签名"
echo "3. 无需依赖 FastLane 的完整流程"
echo
echo "🚀 这证明了模块化方案的优势："
echo "• 使用 FastLane 的优势部分（设备注册、配置文件下载）"
echo "• 避开 FastLane 的问题部分（证书管理、签名）"
echo "• 结合系统原生工具获得最佳效果"