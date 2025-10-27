#!/usr/bin/env swift

import Foundation
import CryptoKit

// 这是一个独立的JWT验证工具，用于测试Apple Developer API的JWT生成

struct JWTHeader: Codable {
    let alg: String
    let kid: String
    let typ: String
}

struct JWTPayload: Codable {
    let iss: String
    let iat: Int
    let exp: Int
    let aud: String
}

extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

func generateTestJWT(keyID: String, issuerID: String, privateKey: String) throws -> String {
    let header = JWTHeader(alg: "ES256", kid: keyID, typ: "JWT")
    
    let now = Date()
    let payload = JWTPayload(
        iss: issuerID,
        iat: Int(now.timeIntervalSince1970),
        exp: Int(now.addingTimeInterval(20 * 60).timeIntervalSince1970),
        aud: "appstoreconnect-v1"
    )
    
    let headerData = try JSONEncoder().encode(header)
    let payloadData = try JSONEncoder().encode(payload)
    
    let headerBase64 = headerData.base64URLEncodedString()
    let payloadBase64 = payloadData.base64URLEncodedString()
    
    let message = "\(headerBase64).\(payloadBase64)"
    
    // 简化的私钥解析和签名
    let cleanKey = privateKey
        .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
        .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
        .replacingOccurrences(of: " ", with: "")
    
    guard let keyData = Data(base64Encoded: cleanKey) else {
        throw NSError(domain: "JWTError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key"])
    }
    
    // 提取32字节私钥
    let keyBytes = Array(keyData)
    let privateKeyData = Data(keyBytes.suffix(32))
    
    let key = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    let messageData = Data(message.utf8)
    let signature = try key.signature(for: messageData)
    
    let signatureBase64 = signature.derRepresentation.base64URLEncodedString()
    
    return "\(message).\(signatureBase64)"
}

// 测试用例
let testKeyID = "XXXXXXXXXX"  // 10位字符
let testIssuerID = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  // UUID格式
let testPrivateKey = """
-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----
"""

print("JWT 测试工具")
print("=============")

if testKeyID == "XXXXXXXXXX" {
    print("请配置有效的测试凭证:")
    print("1. 设置 testKeyID (10位字符)")
    print("2. 设置 testIssuerID (UUID格式)")
    print("3. 设置 testPrivateKey (P8文件内容)")
} else {
    do {
        let jwt = try generateTestJWT(keyID: testKeyID, issuerID: testIssuerID, privateKey: testPrivateKey)
        print("✅ JWT 生成成功")
        print("JWT: \(jwt)")
        
        // 测试API调用
        print("\n🧪 测试API调用...")
        
        guard let url = URL(string: "https://api.appstoreconnect.apple.com/v1/devices") else {
            print("❌ 无效的URL")
            exit(1)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 网络错误: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 无效响应")
                return
            }
            
            print("📡 HTTP状态码: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📥 响应内容: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ API调用成功！")
            } else {
                print("❌ API调用失败")
            }
            
            exit(httpResponse.statusCode == 200 ? 0 : 1)
        }
        
        task.resume()
        
        // 等待响应
        RunLoop.main.run(until: Date().addingTimeInterval(10))
        
    } catch {
        print("❌ JWT生成失败: \(error)")
    }
}