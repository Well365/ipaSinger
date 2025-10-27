#!/bin/bash

echo "🔑 设置 Apple Developer API 凭证"
echo "==============================="
echo
echo "请将以下命令中的占位符替换为您的真实凭证："
echo

cat << 'EOF'
# 设置您的 Apple Developer API 凭证
export APPLE_API_KEY_ID="II1D92HENBJW"
export APPLE_API_ISSUER_ID="2579604c-6184-4fd4-928d-ca71b47ada19"
export APPLE_API_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgViMpk8ddBWVv6jc8
2T1MKi4yur8TXsu0jMUOOCab9AqhRANCAAQbGwzoCm4w8cSqhhWF8kM36qM/fhQ5
ffmN6O5sPZ5eiXIAUxTkxd2JysSUF6tV0SOfTQGJGWdiqC/8c9uguTUB
-----END PRIVATE KEY-----"

# 然后测试连接
swift jwt_debug.swift
EOF

echo
echo "📝 示例（请替换为您的真实值）："
echo "export APPLE_API_KEY_ID=\"ABC123DEFG\""
echo "export APPLE_API_ISSUER_ID=\"12345678-1234-1234-1234-123456789012\""
echo "export APPLE_API_PRIVATE_KEY=\"-----BEGIN PRIVATE KEY-----"
echo "MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg..."
echo "-----END PRIVATE KEY-----\""
echo
echo "🚀 设置完成后运行："
echo "swift jwt_debug.swift"
echo
echo "或者启动应用："
echo "swift run MacSigner"