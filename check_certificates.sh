#!/bin/bash

echo "=========================================="
echo "🔍 macOS Keychain 开发者证书检查工具"
echo "=========================================="
echo ""

# 检查代码签名证书
echo "1️⃣ 代码签名证书列表:"
echo "----------------------------------------"
security find-identity -v -p codesigning

echo ""
echo "2️⃣ 证书详细分析:"
echo "----------------------------------------"

# 计数器
dev_count=0
dist_count=0
total_count=0

# 获取所有证书并分析
while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*[0-9]+\) ]]; then
        total_count=$((total_count + 1))
        
        # 提取证书ID和名称
        cert_id=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+([A-F0-9]+)[[:space:]]+.*/\1/')
        cert_name=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[A-F0-9]+[[:space:]]+"(.*)"/\1/')
        
        echo "证书 #${total_count}:"
        echo "  ID: ${cert_id}"
        echo "  名称: ${cert_name}"
        
        # 判断证书类型
        if [[ $cert_name == *"Development"* ]]; then
            echo "  类型: 🔧 开发证书 (Development)"
            dev_count=$((dev_count + 1))
        elif [[ $cert_name == *"Distribution"* ]]; then
            echo "  类型: 📦 发布证书 (Distribution)" 
            dist_count=$((dist_count + 1))
        else
            echo "  类型: ❓ 其他类型"
        fi
        
        # 检查证书有效期
        cert_info=$(security find-certificate -c "$cert_name" -p 2>/dev/null | openssl x509 -text -noout 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            not_after=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After : //')
            if [[ -n "$not_after" ]]; then
                echo "  到期时间: ${not_after}"
                
                # 检查是否即将过期 (30天内)
                expire_timestamp=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" "+%s" 2>/dev/null)
                current_timestamp=$(date "+%s")
                days_until_expiry=$(( (expire_timestamp - current_timestamp) / 86400 ))
                
                if [[ $days_until_expiry -lt 0 ]]; then
                    echo "  状态: ❌ 已过期"
                elif [[ $days_until_expiry -lt 30 ]]; then
                    echo "  状态: ⚠️  即将过期 (${days_until_expiry}天后)"
                else
                    echo "  状态: ✅ 有效 (${days_until_expiry}天后到期)"
                fi
            fi
        fi
        
        echo ""
    fi
done < <(security find-identity -v -p codesigning)

echo "3️⃣ 证书统计:"
echo "----------------------------------------"
echo "📊 总证书数: ${total_count}"
echo "🔧 开发证书: ${dev_count}"
echo "📦 发布证书: ${dist_count}"
echo ""

echo "4️⃣ P12导出建议:"
echo "----------------------------------------"
if [[ $total_count -gt 0 ]]; then
    echo "✅ 发现可用证书！"
    echo ""
    echo "📝 导出P12证书步骤:"
    echo "1. 打开「钥匙串访问」应用"
    echo "2. 在左侧选择「登录」钥匙串"
    echo "3. 在「种类」中选择「证书」"
    echo "4. 找到以下证书之一:"
    
    # 重新遍历显示推荐的证书
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*[0-9]+\) ]]; then
            cert_name=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[A-F0-9]+[[:space:]]+"(.*)"/\1/')
            if [[ $cert_name == *"Development"* ]]; then
                echo "   🔧 ${cert_name} (推荐用于开发测试)"
            elif [[ $cert_name == *"Distribution"* ]]; then
                echo "   📦 ${cert_name} (推荐用于发布)"
            fi
        fi
    done < <(security find-identity -v -p codesigning)
    
    echo ""
    echo "5. 右键点击证书 → 导出 \"证书名称\""
    echo "6. 文件格式选择「个人信息交换 (.p12)」"
    echo "7. 设置密码并保存"
    echo "8. 在MacSigner的Apple ID配置中选择此P12文件"
else
    echo "❌ 未找到可用的开发者证书！"
    echo ""
    echo "📋 获取证书步骤:"
    echo "1. 登录 https://developer.apple.com"
    echo "2. 进入 Certificates, Identifiers & Profiles"
    echo "3. 创建新的iOS Development或Distribution证书"
    echo "4. 按照指引上传CSR文件"
    echo "5. 下载并安装证书到钥匙串"
fi

echo ""
echo "5️⃣ 快速验证命令:"
echo "----------------------------------------"
echo "# 检查证书有效性"
echo "security find-identity -v -p codesigning"
echo ""
echo "# 查看特定证书详情"
echo "security find-certificate -c \"证书名称\" -p | openssl x509 -text -noout"
echo ""
echo "=========================================="