#!/bin/bash

echo "🔧 P12证书导出工具"
echo "======================"
echo ""

# 检查可用证书
echo "📋 检查可用的开发者证书..."
certs=$(security find-identity -v -p codesigning)
echo "$certs"
echo ""

# 提取证书信息
dev_cert_id="F36DCFA3ACDDB2A058CD1B21650A0DFA250D2B62"
dev_cert_name="Apple Development: Wenhuan Chen (QJJASSCXMJ)"

dist_cert_id="3C03EAB6D64A725A81BB4AEEEAB9E98946D33F70"
dist_cert_name="Apple Distribution: Wenhuan Chen (X855Y85A4V)"

echo "🎯 推荐证书："
echo "1. 开发证书: $dev_cert_name"
echo "2. 发布证书: $dist_cert_name"
echo ""

# 选择要导出的证书
echo "请选择要导出的证书类型："
echo "1) 开发证书 (推荐用于测试)"
echo "2) 发布证书 (用于分发)"
read -p "请输入选择 (1 或 2): " choice

case $choice in
    1)
        selected_id="$dev_cert_id"
        selected_name="$dev_cert_name"
        output_filename="AppleDevelopment_$(date +%Y%m%d).p12"
        ;;
    2)
        selected_id="$dist_cert_id"
        selected_name="$dist_cert_name"
        output_filename="AppleDistribution_$(date +%Y%m%d).p12"
        ;;
    *)
        echo "❌ 无效选择，退出"
        exit 1
        ;;
esac

echo ""
echo "📦 准备导出证书: $selected_name"
echo "💾 输出文件: $output_filename"
echo ""

# 设置导出路径
export_path="$HOME/Desktop/$output_filename"

# 提示输入密码
echo "🔐 请为P12文件设置密码（用于保护证书）："
read -s -p "密码: " p12_password
echo ""
read -s -p "确认密码: " p12_password_confirm
echo ""

if [ "$p12_password" != "$p12_password_confirm" ]; then
    echo "❌ 密码不匹配，请重新运行脚本"
    exit 1
fi

echo ""
echo "🚀 开始导出P12证书..."

# 导出P12证书
# 注意：这个命令可能需要您在钥匙串中允许访问
security export -k login.keychain -t identities -f pkcs12 -o "$export_path" -P "$p12_password" -C "$selected_id"

if [ $? -eq 0 ]; then
    echo "✅ P12证书导出成功！"
    echo ""
    echo "📁 文件位置: $export_path"
    echo "🔑 文件密码: [您刚设置的密码]"
    echo ""
    echo "📋 下一步配置MacSigner："
    echo "1. 打开MacSigner应用"
    echo "2. 点击「Apple ID」按钮"
    echo "3. 填写以下信息："
    echo "   - Apple ID: 您的开发者邮箱"
    echo "   - P12证书路径: $export_path"
    echo "   - P12密码: [您刚设置的密码]"
    echo ""
    echo "🎉 配置完成后即可使用签名功能！"
    
    # 在Finder中显示文件
    open -R "$export_path"
    
else
    echo "❌ 导出失败，可能的原因："
    echo "1. 密码错误"
    echo "2. 证书没有对应的私钥"
    echo "3. 权限问题"
    echo ""
    echo "🔧 解决方法："
    echo "1. 确保证书是您本机生成的（有私钥）"
    echo "2. 在钥匙串访问中手动导出"
    echo "3. 检查钥匙串权限设置"
fi