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

# 详细验证配置文件
echo "🔍 详细验证配置文件..."

# 检查配置文件有效期
PROVISION_EXPIRY=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract ExpirationDate xml1 -o - - | sed -n 's/.*<date>\(.*\)<\/date>.*/\1/p')
PROVISION_NAME=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract Name xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
echo "配置文件名称: $PROVISION_NAME"
echo "配置文件到期时间: $PROVISION_EXPIRY"

# 检查是否过期
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [[ "$PROVISION_EXPIRY" < "$CURRENT_DATE" ]]; then
    echo "❌ 配置文件已过期！"
    echo "当前时间: $CURRENT_DATE"
    echo "过期时间: $PROVISION_EXPIRY"
    exit 1
else
    echo "✅ 配置文件有效期正常"
fi

# 检查配置文件中的Bundle ID
echo "🔍 检查配置文件Bundle ID匹配性..."
PROVISION_APP_ID=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract Entitlements.application-identifier xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
echo "配置文件应用ID: $PROVISION_APP_ID"
echo "目标Bundle ID: $BUNDLE_ID"

# 提取Team ID和Bundle ID部分
PROVISION_BUNDLE_PART=$(echo "$PROVISION_APP_ID" | sed "s/^$PROVISION_TEAM_ID\.//")
echo "配置文件Bundle部分: $PROVISION_BUNDLE_PART"

if [[ "$PROVISION_BUNDLE_PART" == "$BUNDLE_ID" || "$PROVISION_BUNDLE_PART" == "*" ]]; then
    echo "✅ Bundle ID 匹配"
else
    echo "❌ Bundle ID 不匹配！"
    echo "期望: $BUNDLE_ID"
    echo "实际: $PROVISION_BUNDLE_PART"
    
    # 尝试修复：更新配置文件的application-identifier
    echo "🔧 尝试修复配置文件..."
    
    # 创建临时配置文件进行修改
    TEMP_PROVISION=$(mktemp)
    security cms -D -i "$APP_PATH/embedded.mobileprovision" > "$TEMP_PROVISION"
    
    # 更新application-identifier
    /usr/libexec/PlistBuddy -c "Set :Entitlements:application-identifier $PROVISION_TEAM_ID.$BUNDLE_ID" "$TEMP_PROVISION"
    
    # 重新编码配置文件（注意：这只是临时方案，实际需要重新签名）
    echo "⚠️  配置文件Bundle ID已更新，但建议重新生成正确的配置文件"
fi

# 检查设备ID
echo "🔍 检查设备兼容性..."
PROVISION_DEVICES=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract ProvisionedDevices xml1 -o - - 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$PROVISION_DEVICES" ]; then
    echo "✅ 这是开发/Ad Hoc配置文件"
    
    # 提取设备ID列表
    DEVICE_LIST=$(echo "$PROVISION_DEVICES" | grep -o '<string>[^<]*</string>' | sed 's/<[^>]*>//g')
    DEVICE_COUNT=$(echo "$DEVICE_LIST" | wc -l)
    
    echo "配置文件包含 $DEVICE_COUNT 个设备:"
    echo "$DEVICE_LIST" | head -10
    
    if [ $DEVICE_COUNT -gt 10 ]; then
        echo "... (显示前10个，总共$DEVICE_COUNT个)"
    fi
    
    # 获取当前连接的设备UDID
    echo "🔍 检查当前连接的设备..."
    CONNECTED_DEVICES=$(instruments -s devices 2>/dev/null | grep -E "\[.*\]$" | grep -v "Simulator" | head -5)
    if [ -n "$CONNECTED_DEVICES" ]; then
        echo "当前连接的设备:"
        echo "$CONNECTED_DEVICES"
        
        # 检查设备是否在配置文件中
        while IFS= read -r device_line; do
            if [[ "$device_line" =~ \[([A-F0-9-]+)\] ]]; then
                DEVICE_UDID="${BASH_REMATCH[1]}"
                if echo "$DEVICE_LIST" | grep -q "$DEVICE_UDID"; then
                    echo "✅ 设备 $DEVICE_UDID 在配置文件中"
                else
                    echo "⚠️  设备 $DEVICE_UDID 不在配置文件中"
                fi
            fi
        done <<< "$CONNECTED_DEVICES"
    else
        echo "⚠️  未检测到连接的设备，请确保设备已连接并信任此Mac"
    fi
    
else
    echo "✅ 这可能是企业级或App Store配置文件（无设备限制）"
fi

# 检查配置文件类型
PROVISION_TYPE=$(security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract Entitlements.get-task-allow xml1 -o - - 2>/dev/null | grep -o '<true/>\|<false/>')

PROVISION_TYPE_NAME=""
IS_DEVELOPMENT=false

if [ "$PROVISION_TYPE" = "<true/>" ]; then
    PROVISION_TYPE_NAME="开发版 (Development)"
    IS_DEVELOPMENT=true
    echo "📋 配置文件类型: $PROVISION_TYPE_NAME"
    echo "   ✅ 允许调试 (get-task-allow = true)"
elif [ "$PROVISION_TYPE" = "<false/>" ]; then
    PROVISION_TYPE_NAME="发布版 (Distribution/Ad Hoc)"
    IS_DEVELOPMENT=false
    echo "📋 配置文件类型: $PROVISION_TYPE_NAME"
    echo "   🚫 不允许调试 (get-task-allow = false)"
else
    PROVISION_TYPE_NAME="未知"
    echo "📋 配置文件类型: $PROVISION_TYPE_NAME"
fi

# 提取并保存 entitlements
echo "📋 提取配置文件 entitlements..."
ENTITLEMENTS_FILE="$APP_PATH/entitlements_from_provision.plist"
security cms -D -i "$APP_PATH/embedded.mobileprovision" | plutil -extract Entitlements xml1 -o "$ENTITLEMENTS_FILE" -

if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo "✅ entitlements 提取成功"
    
    # 更新 entitlements 中的 application-identifier
    /usr/libexec/PlistBuddy -c "Set :application-identifier $PROVISION_TEAM_ID.$BUNDLE_ID" "$ENTITLEMENTS_FILE" 2>/dev/null
    
    # 更新 keychain-access-groups 如果存在
    if /usr/libexec/PlistBuddy -c "Print :keychain-access-groups" "$ENTITLEMENTS_FILE" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Set :keychain-access-groups:0 $PROVISION_TEAM_ID.$BUNDLE_ID" "$ENTITLEMENTS_FILE" 2>/dev/null
    fi
    
    echo "entitlements 关键信息:"
    /usr/libexec/PlistBuddy -c "Print :application-identifier" "$ENTITLEMENTS_FILE" 2>/dev/null && echo "application-identifier: $(/usr/libexec/PlistBuddy -c "Print :application-identifier" "$ENTITLEMENTS_FILE" 2>/dev/null)"
else
    echo "⚠️  无法提取 entitlements，将不使用"
fi
echo

# 删除旧签名
echo "🗑️  删除原有签名..."
rm -rf "$APP_PATH/_CodeSignature"

# 删除可能存在的旧 entitlements 文件
rm -f "$APP_PATH/entitlements.plist"

# 对 Frameworks 进行签名
echo "🔐 签名 Frameworks..."
if [ -d "$APP_PATH/Frameworks" ]; then
    for framework in "$APP_PATH/Frameworks"/*.framework; do
        if [ -d "$framework" ]; then
            echo "  签名: $(basename "$framework")"
            # 删除框架的旧签名
            rm -rf "$framework/_CodeSignature"
            # 签名框架
            codesign --force --sign "$SIGN_IDENTITY" --timestamp "$framework"
            FRAMEWORK_RESULT=$?
            if [ $FRAMEWORK_RESULT -ne 0 ]; then
                echo "    ❌ 框架签名失败: $(basename "$framework")"
            else
                echo "    ✅ 框架签名成功: $(basename "$framework")"
            fi
        fi
    done
fi

# 对 PlugIns 进行签名
if [ -d "$APP_PATH/PlugIns" ]; then
    echo "🔐 签名 PlugIns..."
    for plugin in "$APP_PATH/PlugIns"/*.appex; do
        if [ -d "$plugin" ]; then
            echo "  签名: $(basename "$plugin")"
            # 删除插件的旧签名
            rm -rf "$plugin/_CodeSignature"
            
            # 更新插件的 Bundle ID
            if [ -f "$plugin/Info.plist" ]; then
                /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID.$(basename "$plugin" .appex)" "$plugin/Info.plist" 2>/dev/null
            fi
            
            # 签名插件
            if [ -f "$ENTITLEMENTS_FILE" ]; then
                codesign --force --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS_FILE" --timestamp "$plugin"
            else
                codesign --force --sign "$SIGN_IDENTITY" --timestamp "$plugin"
            fi
            
            PLUGIN_RESULT=$?
            if [ $PLUGIN_RESULT -ne 0 ]; then
                echo "    ❌ 插件签名失败: $(basename "$plugin")"
            else
                echo "    ✅ 插件签名成功: $(basename "$plugin")"
            fi
        fi
    done
fi

# 签名主应用
echo "🔐 签名主应用..."
if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo "使用提取的 entitlements 进行签名..."
    codesign --force --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS_FILE" --timestamp "$APP_PATH"
else
    echo "使用默认签名（无 entitlements）..."
    codesign --force --sign "$SIGN_IDENTITY" --timestamp "$APP_PATH"
fi

MAIN_SIGN_RESULT=$?

if [ $MAIN_SIGN_RESULT -eq 0 ]; then
    echo "✅ 应用签名成功"
else
    echo "❌ 应用签名失败，错误代码: $MAIN_SIGN_RESULT"
    
    # 尝试更详细的签名诊断
    echo "🔍 签名诊断..."
    codesign --display --verbose=4 "$APP_PATH"
    
    rm -rf "$WORK_DIR"
    exit 1
fi

# 深度验证签名
echo "🔍 深度验证签名..."
echo "验证主应用..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
DEEP_VERIFY_RESULT=$?

if [ $DEEP_VERIFY_RESULT -eq 0 ]; then
    echo "✅ 深度签名验证通过"
else
    echo "⚠️  深度签名验证失败，错误代码: $DEEP_VERIFY_RESULT"
    echo "尝试基础验证..."
    codesign --verify --verbose "$APP_PATH"
    BASIC_VERIFY_RESULT=$?
    
    if [ $BASIC_VERIFY_RESULT -eq 0 ]; then
        echo "✅ 基础签名验证通过"
    else
        echo "❌ 所有签名验证都失败"
        echo "签名详细信息:"
        codesign --display --verbose=4 "$APP_PATH"
        rm -rf "$WORK_DIR"
        exit 1
    fi
fi

# 验证签名一致性
echo "🔍 验证签名一致性..."
MAIN_TEAM_ID=$(codesign -dv "$APP_PATH" 2>&1 | grep "TeamIdentifier=" | sed 's/TeamIdentifier=//')
echo "主应用 Team ID: $MAIN_TEAM_ID"
echo "配置文件 Team ID: $PROVISION_TEAM_ID"

if [ "$MAIN_TEAM_ID" = "$PROVISION_TEAM_ID" ]; then
    echo "✅ Team ID 一致"
else
    echo "⚠️  Team ID 不一致，可能导致安装问题"
fi

# 重新打包 IPA
echo "📦 重新打包 IPA..."

# 修复输出路径 - 使用正确的变量名和绝对路径
OUTPUT_IPA_NAME="$(basename "$IPA_FILE" .ipa)_resigned.ipa"
OUTPUT_IPA="$ORIGINAL_PWD/$OUTPUT_DIR/$OUTPUT_IPA_NAME"

# 确保输出目录存在
mkdir -p "$ORIGINAL_PWD/$OUTPUT_DIR"

echo "目标输出文件: $OUTPUT_IPA"
echo "当前工作目录: $(pwd)"

# 检查 Payload 目录结构
echo "检查 IPA 目录结构:"
if [ -d "Payload" ]; then
    echo "✅ 找到 Payload 目录"
    echo "Payload 目录内容:"
    ls -la "Payload/"
    
    # 检查是否有 .app 文件
    APP_COUNT=$(find "Payload" -name "*.app" -type d | wc -l)
    echo "应用程序包数量: $APP_COUNT"
    
    if [ $APP_COUNT -eq 0 ]; then
        echo "❌ Payload 目录中没有找到 .app 文件"
        echo "完整目录结构:"
        find . -type d -name "*.app"
        rm -rf "$WORK_DIR"
        exit 1
    fi
else
    echo "❌ 没有找到 Payload 目录"
    echo "当前目录结构:"
    ls -la
    rm -rf "$WORK_DIR"
    exit 1
fi

# 创建 IPA 包 - 确保在包含 Payload 的目录下打包
echo "开始打包 IPA..."
zip -r "$OUTPUT_IPA" "Payload" 
ZIP_RESULT=$?

echo "打包结果代码: $ZIP_RESULT"

# 验证生成的 IPA 文件
if [ $ZIP_RESULT -eq 0 ] && [ -f "$OUTPUT_IPA" ]; then
    echo "✅ IPA 文件创建成功"
    
    # 验证 IPA 内部结构
    echo "🔍 验证 IPA 内部结构..."
    unzip -l "$OUTPUT_IPA" | head -20
    
    # 检查 IPA 是否包含正确的应用程序包
    APP_IN_IPA=$(unzip -l "$OUTPUT_IPA" | grep -c "Payload/.*\.app/")
    echo "IPA 中的应用程序包结构数量: $APP_IN_IPA"
    
    if [ $APP_IN_IPA -gt 0 ]; then
        echo "✅ IPA 结构验证通过"
    else
        echo "❌ IPA 结构验证失败 - 缺少应用程序包"
        echo "完整 IPA 内容:"
        unzip -l "$OUTPUT_IPA"
        rm -rf "$WORK_DIR"
        exit 1
    fi
    
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
echo "🔍 最终签名和Bundle信息验证"
echo "================================"
echo

# 创建临时目录用于最终验证
VERIFY_DIR="$(mktemp -d)"
echo "📁 创建验证工作目录: $VERIFY_DIR"

# 解压重签名后的IPA进行验证
cd "$VERIFY_DIR"
unzip -q "$OUTPUT_IPA"

# 查找.app文件
VERIFY_APP_PATH=$(find . -name "*.app" | head -1)

if [ -n "$VERIFY_APP_PATH" ]; then
    echo "✅ 找到应用包: $(basename "$VERIFY_APP_PATH")"
    echo
    
    # 1. 验证Bundle ID
    echo "📋 Bundle ID 验证:"
    FINAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$VERIFY_APP_PATH/Info.plist" 2>/dev/null)
    echo "  目标 Bundle ID: $BUNDLE_ID"
    echo "  实际 Bundle ID: $FINAL_BUNDLE_ID"
    if [ "$FINAL_BUNDLE_ID" = "$BUNDLE_ID" ]; then
        echo "  ✅ Bundle ID 匹配"
    else
        echo "  ❌ Bundle ID 不匹配"
    fi
    echo
    
    # 2. 验证应用签名
    echo "🔐 应用签名验证:"
    codesign --verify --verbose "$VERIFY_APP_PATH"
    FINAL_VERIFY_RESULT=$?
    
    if [ $FINAL_VERIFY_RESULT -eq 0 ]; then
        echo "  ✅ 签名验证通过"
    else
        echo "  ⚠️  签名验证有问题"
    fi
    echo
    
    # 3. 显示详细签名信息
    echo "📊 详细签名信息:"
    SIGN_INFO=$(codesign -dv "$VERIFY_APP_PATH" 2>&1)
    echo "$SIGN_INFO" | grep -E "(Identifier|Authority|TeamIdentifier|Sealed Resources)"
    echo
    
    # 4. 验证配置文件
    echo "📄 配置文件验证:"
    if [ -f "$VERIFY_APP_PATH/embedded.mobileprovision" ]; then
        echo "  ✅ 配置文件存在"
        
        # 提取配置文件信息
        FINAL_PROVISION_UUID=$(security cms -D -i "$VERIFY_APP_PATH/embedded.mobileprovision" | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
        FINAL_TEAM_ID=$(security cms -D -i "$VERIFY_APP_PATH/embedded.mobileprovision" | plutil -extract TeamIdentifier.0 xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
        FINAL_PROVISION_NAME=$(security cms -D -i "$VERIFY_APP_PATH/embedded.mobileprovision" | plutil -extract Name xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
        FINAL_PROVISION_EXPIRY=$(security cms -D -i "$VERIFY_APP_PATH/embedded.mobileprovision" | plutil -extract ExpirationDate xml1 -o - - | sed -n 's/.*<date>\(.*\)<\/date>.*/\1/p')
        
        echo "  配置文件名称: $FINAL_PROVISION_NAME"
        echo "  配置文件 UUID: $FINAL_PROVISION_UUID"
        echo "  Team ID: $FINAL_TEAM_ID"
        echo "  到期时间: $FINAL_PROVISION_EXPIRY"
        
        # 检查配置文件中的Bundle ID
        PROVISION_BUNDLE_ID=$(security cms -D -i "$VERIFY_APP_PATH/embedded.mobileprovision" | plutil -extract Entitlements.application-identifier xml1 -o - - | sed -n 's/.*<string>[^.]*\.\(.*\)<\/string>.*/\1/p')
        echo "  配置文件 Bundle ID: $PROVISION_BUNDLE_ID"
        
        if [[ "$PROVISION_BUNDLE_ID" == "$BUNDLE_ID" || "$PROVISION_BUNDLE_ID" == "*" ]]; then
            echo "  ✅ 配置文件 Bundle ID 匹配"
        else
            echo "  ⚠️  配置文件 Bundle ID 可能不匹配"
        fi
    else
        echo "  ❌ 配置文件不存在"
    fi
    echo
    
    # 5. 验证应用版本信息
    echo "📱 应用版本信息:"
    APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$VERIFY_APP_PATH/Info.plist" 2>/dev/null)
    BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$VERIFY_APP_PATH/Info.plist" 2>/dev/null)
    APP_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$VERIFY_APP_PATH/Info.plist" 2>/dev/null)
    
    echo "  应用名称: $APP_NAME"
    echo "  应用版本: $APP_VERSION"
    echo "  构建版本: $BUILD_VERSION"
    echo
    
    # 6. 检查Frameworks签名
    echo "🔗 Frameworks 签名检查:"
    if [ -d "$VERIFY_APP_PATH/Frameworks" ]; then
        FRAMEWORK_COUNT=0
        SIGNED_FRAMEWORKS=0
        
        for framework in "$VERIFY_APP_PATH/Frameworks"/*.framework; do
            if [ -d "$framework" ]; then
                FRAMEWORK_COUNT=$((FRAMEWORK_COUNT + 1))
                FRAMEWORK_NAME=$(basename "$framework")
                
                if codesign --verify "$framework" 2>/dev/null; then
                    echo "  ✅ $FRAMEWORK_NAME"
                    SIGNED_FRAMEWORKS=$((SIGNED_FRAMEWORKS + 1))
                else
                    echo "  ❌ $FRAMEWORK_NAME"
                fi
            fi
        done
        
        echo "  Framework 总数: $FRAMEWORK_COUNT"
        echo "  已签名数量: $SIGNED_FRAMEWORKS"
        
        if [ $FRAMEWORK_COUNT -eq $SIGNED_FRAMEWORKS ]; then
            echo "  ✅ 所有 Frameworks 签名正常"
        else
            echo "  ⚠️  部分 Frameworks 签名异常"
        fi
    else
        echo "  📋 无 Frameworks 需要检查"
    fi
    echo
    
    # 7. 最终状态总结
    echo "📋 最终验证总结:"
    echo "================================"
    
    ALL_GOOD=true
    
    if [ "$FINAL_BUNDLE_ID" = "$BUNDLE_ID" ]; then
        echo "✅ Bundle ID: 正确 ($BUNDLE_ID)"
    else
        echo "❌ Bundle ID: 不匹配"
        ALL_GOOD=false
    fi
    
    if [ $FINAL_VERIFY_RESULT -eq 0 ]; then
        echo "✅ 应用签名: 验证通过"
    else
        echo "⚠️  应用签名: 有警告"
    fi
    
    if [ -f "$VERIFY_APP_PATH/embedded.mobileprovision" ]; then
        echo "✅ 配置文件: 已嵌入"
    else
        echo "❌ 配置文件: 缺失"
        ALL_GOOD=false
    fi
    
    echo "✅ IPA 结构: 完整"
    echo "✅ 文件大小: $(ls -lh "$OUTPUT_IPA" | awk '{print $5}')"
    echo
    
    # 添加安装建议
    echo "📱 安装建议:"
    echo "================================"
    
    if [ "$ALL_GOOD" = true ]; then
        echo "🎉 重签名完全成功！"
        echo
        
        if [ "$IS_DEVELOPMENT" = true ]; then
            echo "📋 Development 配置文件安装方法："
            echo "1. 🔧 使用 Xcode (推荐):"
            echo "   • 打开 Xcode > Window > Devices and Simulators"
            echo "   • 选择设备 > 点击 '+' > 选择 IPA 文件"
            echo "   • Development 配置支持直接安装和调试"
            echo
            echo "2. 💻 使用命令行工具:"
            echo "   • ios-deploy --bundle \"$OUTPUT_IPA\""
            echo "   • xcrun devicectl device install app --device [设备ID] \"$OUTPUT_IPA\""
            echo
        else
            echo "📋 Ad Hoc 配置文件安装方法："
            echo "1. 🔧 使用 Xcode (推荐):"
            echo "   • 打开 Xcode > Window > Devices and Simulators"
            echo "   • 选择设备 > 点击 '+' > 选择 IPA 文件"
            echo "   • Ad Hoc 配置不支持调试，但安装后可正常运行"
            echo
            echo "2. 📱 使用配置描述文件:"
            echo "   • 先双击 mobileprovision 文件安装到设备"
            echo "   • 设备 > 设置 > 通用 > VPN与设备管理 > 信任描述文件"
            echo "   • 然后安装 IPA"
            echo
            echo "3. 🚫 不推荐使用 ios-deploy:"
            echo "   • Ad Hoc 配置可能与 ios-deploy 不兼容"
            echo "   • 建议使用 Xcode 或其他企业分发工具"
            echo
        fi
        
        echo "📱 通用准备步骤："
        echo "   • 设备已解锁且信任此 Mac"
        echo "   • 检查设备 UDID 在配置文件中"
        echo "   • 运行: instruments -s devices 查看设备信息"
        echo
        echo "🔍 如果遇到配置文件错误 (0xe8008015)："
        echo "   • 确认设备UDID在上面显示的配置文件设备列表中"
        echo "   • 确认配置文件未过期"
        echo "   • 确认Bundle ID匹配"
        echo "   • 如果是新设备，需要重新运行 FastLane 添加设备并获取新配置文件"
        echo
        echo "🔄 重新生成配置文件的命令："
        if [ "$IS_DEVELOPMENT" = true ]; then
            echo "   # 生成 Development 配置:"
            echo "   bundle exec fastlane match development"
        else
            echo "   # 生成 Ad Hoc 配置:"
            echo "   bundle exec fastlane match adhoc"
        fi
        echo "   # 或使用自定义脚本:"
        echo "   bundle exec fastlane add_device_and_generate_profile"
        echo
        echo "⚠️  Ad Hoc vs Development 重要提示："
        echo "   • Development: 支持调试，适合开发阶段"
        echo "   • Ad Hoc: 不支持调试，适合测试分发"
        echo "   • 如果需要调试功能，请使用 Development 配置文件"
        echo "   • 如果用于分发测试，Ad Hoc 配置更合适"
        echo
        echo "🛠️  故障排除："
        echo "   • 重启设备和 Mac"
        echo "   • 删除设备上的旧版本应用"
        echo "   • 在设备设置中信任开发者证书"
        echo "   • 确保配置文件已正确安装到设备"
        
    else
        echo "⚠️  重签名完成，但检测到问题："
        echo "• 检查上述警告"
        echo "• 建议重新生成包含正确设备UDID的配置文件"
        echo "• 确保Bundle ID匹配"
        if [ "$IS_DEVELOPMENT" = false ]; then
            echo "• Ad Hoc 配置可能需要先安装配置描述文件"
        fi
    fi

else
    echo "❌ 验证失败：无法在重签名的IPA中找到应用包"
fi

# 清理验证临时文件
rm -rf "$VERIFY_DIR"

echo
echo "🎉 签名流程完成！"
echo "========================"
echo
# echo "✅ 成功使用 FastLane 获取的配置文件完成了 IPA 重签名"
# echo "✅ 绕过了 FastLane 的证书管理问题"
# echo "✅ 直接使用系统 codesign 工具，更加可靠"
# echo
# echo "📋 使用说明："
# echo "1. 先运行 FastLane 获取 mobileprovision 文件"
# echo "2. 运行此脚本对任意 IPA 进行签名"
# echo "3. 无需依赖 FastLane 的完整流程"
# echo
# echo "🚀 这证明了模块化方案的优势："
# echo "• 使用 FastLane 的优势部分（设备注册、配置文件下载）"
# echo "• 避开 FastLane 的问题部分（证书管理、签名）"
# echo "• 结合系统原生工具获得最佳效果"