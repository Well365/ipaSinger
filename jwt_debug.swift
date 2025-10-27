#!/usr/bin/env swift

import Foundation
import CryptoKit

// 简化的配置加载
struct DebugConfig {
    let keyID: String
    let issuerID: String
    let privateKey: String
    
    static func load() -> DebugConfig? {
        let defaults = UserDefaults.standard
        if let keyID = defaults.string(forKey: "AppleAPIKeyID"),
           let issuerID = defaults.string(forKey: "AppleAPIIssuerID"),
           let privateKey = defaults.string(forKey: "AppleAPIPrivateKey"),
           !keyID.isEmpty, !issuerID.isEmpty, !privateKey.isEmpty {
            return DebugConfig(keyID: keyID, issuerID: issuerID, privateKey: privateKey)
        }
        return nil
    }
}

// JWT 结构
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

// Base64URL 编码扩展
extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

func parseP8PrivateKey(_ p8String: String) throws -> Data {
    print("🔑 分析 P8 私钥格式...")
    
    // 移除PEM头尾和换行符
    let cleanKey = p8String
        .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
        .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "\r", with: "")
        .replacingOccurrences(of: " ", with: "")
    
    print("📏 清理后的 Base64 长度: \(cleanKey.count)")
    print("🔤 前50个字符: \(String(cleanKey.prefix(50)))")
    
    guard let keyData = Data(base64Encoded: cleanKey) else {
        print("❌ Base64 解码失败")
        throw NSError(domain: "JWT", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的私钥格式"])
    }
    
    print("📦 解码后的数据长度: \(keyData.count) 字节")
    print("🔢 前16个字节: \(keyData.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")
    
    let keyBytes = Array(keyData)
    
    // 查找私钥开始位置的多种方法
    print("🔍 查找私钥开始位置...")
    
    // 方法1: 查找 0x04 标记后的32字节
    for i in 0..<(keyBytes.count - 32) {
        if keyBytes[i] == 0x04 && i + 32 < keyBytes.count {
            let candidate = Data(keyBytes[(i+1)...(i+32)])
            print("✓ 找到可能的私钥位置 \(i+1), 长度: 32")
            print("🔢 候选私钥: \(candidate.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " "))...")
            return candidate
        }
    }
    
    // 方法2: 查找 0x20 0x04 序列
    for i in 0..<(keyBytes.count - 33) {
        if keyBytes[i] == 0x20 && keyBytes[i+1] == 0x04 {
            let candidate = Data(keyBytes[(i+2)...(i+33)])
            print("✓ 找到 0x20 0x04 序列位置 \(i), 私钥位置: \(i+2)")
            print("🔢 候选私钥: \(candidate.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " "))...")
            return candidate
        }
    }
    
    // 方法3: 从末尾提取32字节
    if keyBytes.count >= 32 {
        let candidate = Data(keyBytes.suffix(32))
        print("⚠️  使用后32字节作为私钥")
        print("🔢 候选私钥: \(candidate.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " "))...")
        return candidate
    }
    
    print("❌ 无法找到有效的私钥数据")
    throw NSError(domain: "JWT", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法解析私钥"])
}

func generateJWT(config: DebugConfig) throws -> String {
    print("🏗️  生成 JWT Token...")
    
    let header = JWTHeader(alg: "ES256", kid: config.keyID, typ: "JWT")
    
    let now = Date()
    let iat = Int(now.timeIntervalSince1970)
    let exp = Int(now.addingTimeInterval(20 * 60).timeIntervalSince1970)
    
    let payload = JWTPayload(
        iss: config.issuerID,
        iat: iat,
        exp: exp,
        aud: "appstoreconnect-v1"
    )
    
    print("📋 JWT 参数:")
    print("   Key ID: \(config.keyID)")
    print("   Issuer ID: \(config.issuerID)")
    print("   签发时间: \(iat) (\(Date(timeIntervalSince1970: TimeInterval(iat))))")
    print("   过期时间: \(exp) (\(Date(timeIntervalSince1970: TimeInterval(exp))))")
    
    let headerData = try JSONEncoder().encode(header)
    let payloadData = try JSONEncoder().encode(payload)
    
    let headerBase64 = headerData.base64URLEncodedString()
    let payloadBase64 = payloadData.base64URLEncodedString()
    
    print("🔤 Base64URL 编码:")
    print("   Header: \(headerBase64)")
    print("   Payload: \(payloadBase64)")
    
    let message = "\(headerBase64).\(payloadBase64)"
    print("📝 待签名消息: \(message)")
    
    // 解析私钥
    let privateKeyData = try parseP8PrivateKey(config.privateKey)
    let key = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    
    print("🔐 开始签名...")
    let messageData = Data(message.utf8)
    let signature = try key.signature(for: messageData)
    
    // 尝试不同的签名格式
    let rawSignature = signature.rawRepresentation.base64URLEncodedString()
    let derSignature = signature.derRepresentation.base64URLEncodedString()
    
    print("📝 签名格式:")
    print("   Raw: \(rawSignature) (长度: \(rawSignature.count))")
    print("   DER: \(derSignature) (长度: \(derSignature.count))")
    
    // Apple 要求 DER 格式
    let jwt = "\(message).\(derSignature)"
    print("✅ JWT 生成完成:")
    print("   长度: \(jwt.count)")
    print("   Token: \(jwt)")
    
    return jwt
}

func testAPIConnection(jwt: String) {
    print("🌐 测试 API 连接...")
    
    let url = URL(string: "https://api.appstoreconnect.apple.com/v1/devices")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    print("📤 发送请求到: \(url)")
    print("🔑 Authorization: Bearer \(jwt.prefix(50))...")
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ 网络错误: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效响应")
            return
        }
        
        print("📥 响应状态: \(httpResponse.statusCode)")
        print("📋 响应头:")
        for (key, value) in httpResponse.allHeaderFields {
            print("   \(key): \(value)")
        }
        
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            print("📝 响应内容:")
            print(responseString)
            
            if httpResponse.statusCode == 401 {
                print("🔍 401 错误分析:")
                print("• 检查 Key ID 是否正确")
                print("• 检查 Issuer ID 是否正确")
                print("• 检查私钥格式是否正确")
                print("• 检查证书是否有正确的权限")
                print("• 确认在 App Store Connect 中启用了 API 访问")
            }
        }
    }.resume()
    
    semaphore.wait()
}

func main() {
    print("🧪 Apple Developer API JWT 调试工具")
    print("==================================")
    print()
    
    var config = DebugConfig.load()
    
    if config == nil {
        print("⚠️  未找到保存的配置，使用测试配置")
        // 使用从日志中看到的配置值进行测试
        config = DebugConfig(
            keyID: "3CARDK3S63",
            issuerID: "2579604c-6184-4fd4-928d-ca71b47ada19",
            privateKey: """
            -----BEGIN PRIVATE KEY-----
            MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgmZOINWzGbfR2dJyT
            wWRUZcmVnXUNKSDjRwqh5gd9pZehRANCAATInyF5ITWL0yNRp95PaNu8j4dkUOiB
            a2V4WnrEXAjPiJ7ZLzS8EcLGZNi4AqMaBLJGKoK4sXqwLnJzZGj+pOHF
            -----END PRIVATE KEY-----
            """
        )
    }
    
    guard let finalConfig = config else {
        print("❌ 无法获取配置")
        exit(1)
    }
    
    do {
        let jwt = try generateJWT(config: finalConfig)
        print()
        testAPIConnection(jwt: jwt)
    } catch {
        print("❌ 错误: \(error)")
        exit(1)
    }
}

main()