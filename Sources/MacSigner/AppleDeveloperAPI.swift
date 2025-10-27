import Foundation
import CryptoKit

// MARK: - Apple Developer API Client
class AppleDeveloperAPI {
    private let keyID: String
    private let issuerID: String
    private let privateKey: String
    private let baseURL = "https://api.appstoreconnect.apple.com"
    
    init(keyID: String, issuerID: String, privateKey: String) {
        self.keyID = keyID
        self.issuerID = issuerID
        self.privateKey = privateKey
        
        print("[AppleDeveloperAPI] Initialized with:")
        print("[AppleDeveloperAPI] Key ID: \(keyID)")
        print("[AppleDeveloperAPI] Issuer ID: \(issuerID)")
        print("[AppleDeveloperAPI] Private Key length: \(privateKey.count) characters")
    }
    
    // MARK: - 配置验证
    func validateConfiguration() throws {
        // 验证Key ID格式 (应该是10个字符)
        guard keyID.count == 10 else {
            throw APIError.apiError("Key ID 应该是10个字符，当前: \(keyID.count)")
        }
        
        // 验证Issuer ID格式 (应该是UUID)
        guard UUID(uuidString: issuerID) != nil else {
            throw APIError.apiError("Issuer ID 应该是有效的UUID格式")
        }
        
        // 验证私钥格式
        guard privateKey.contains("-----BEGIN PRIVATE KEY-----") && 
              privateKey.contains("-----END PRIVATE KEY-----") else {
            throw APIError.apiError("私钥应该是有效的PEM格式 (.p8文件内容)")
        }
        
        // 尝试解析私钥
        _ = try parseP8PrivateKey(privateKey)
        
        print("[AppleDeveloperAPI] Configuration validation passed ✅")
    }
    
    // MARK: - 测试方法
    func testJWTGeneration() throws -> String {
        print("[Test] Testing JWT generation...")
        let jwt = try generateJWT()
        print("[Test] JWT generated successfully ✅")
        return jwt
    }
    
    func testAPIConnection() async throws {
        print("[Test] Testing API connection...")
        _ = try await listDevices()
        print("[Test] API connection successful ✅")
    }
    
    // MARK: - JWT Token Generation
    private func generateJWT() throws -> String {
        let header = JWTHeader(alg: "ES256", kid: keyID, typ: "JWT")
        
        let now = Date()
        let payload = JWTPayload(
            iss: issuerID,
            iat: Int(now.timeIntervalSince1970), // 签发时间
            exp: Int(now.addingTimeInterval(20 * 60).timeIntervalSince1970), // 20分钟有效期
            aud: "appstoreconnect-v1"
        )
        
        print("[JWT] Generating JWT token...")
        print("[JWT] Key ID: \(keyID)")
        print("[JWT] Issuer ID: \(issuerID)")
        print("[JWT] Issued at: \(payload.iat)")
        print("[JWT] Expires at: \(payload.exp)")
        
        let headerData = try JSONEncoder().encode(header)
        let payloadData = try JSONEncoder().encode(payload)
        
        let headerBase64 = headerData.base64URLEncodedString()
        let payloadBase64 = payloadData.base64URLEncodedString()
        
        print("[JWT] Header: \(headerBase64)")
        print("[JWT] Payload: \(payloadBase64)")
        
        let message = "\(headerBase64).\(payloadBase64)"
        let signature = try signMessage(message)
        
        let jwt = "\(message).\(signature)"
        print("[JWT] Generated JWT length: \(jwt.count)")
        print("[JWT] JWT: \(jwt.prefix(50))...")
        
        return jwt
    }
    
    private func signMessage(_ message: String) throws -> String {
        print("[JWT] Signing message: \(message)")
        
        // 解析P8私钥
        let privateKeyData = try parseP8PrivateKey(privateKey)
        print("[JWT] Private key data length: \(privateKeyData.count) bytes")
        
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
        
        let messageData = Data(message.utf8)
        let signature = try key.signature(for: messageData)
        
        // Apple 要求使用 DER 格式的签名，而不是原始格式
        let derSignature = signature.derRepresentation.base64URLEncodedString()
        print("[JWT] Signature length: \(derSignature.count)")
        
        return derSignature
    }
    
    private func parseP8PrivateKey(_ p8String: String) throws -> Data {
        // 移除PEM头尾和换行符
        let cleanKey = p8String
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let keyData = Data(base64Encoded: cleanKey) else {
            throw APIError.invalidPrivateKey
        }
        
        // 更完整的P8私钥解析
        // P8格式是PKCS#8，需要提取原始私钥
        let keyBytes = Array(keyData)
        
        // 查找 P-256 私钥的OID序列 (1.2.840.10045.3.1.7)
        // 这是一个简化的解析，实际应用中可能需要更完整的ASN.1解析
        if let startIndex = findPrivateKeyStart(in: keyBytes) {
            let endIndex = min(startIndex + 32, keyBytes.count)
            if endIndex - startIndex >= 32 {
                return Data(keyBytes[startIndex..<endIndex])
            }
        }
        
        // 如果找不到标准格式，尝试从末尾提取32字节
        if keyBytes.count >= 32 {
            return Data(keyBytes.suffix(32))
        }
        
        throw APIError.invalidPrivateKey
    }
    
    private func findPrivateKeyStart(in bytes: [UInt8]) -> Int? {
        // 查找私钥数据的开始位置
        // P-256私钥通常跟在特定的ASN.1序列之后
        for i in 0..<(bytes.count - 32) {
            if i > 0 && bytes[i] == 0x04 && bytes[i-1] == 0x20 {
                return i + 1
            }
        }
        return nil
    }
    
    // MARK: - API请求
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        print("[API] Making \(method) request to: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let jwt = try generateJWT()
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
            if let bodyString = String(data: body, encoding: .utf8) {
                print("[API] Request body: \(bodyString)")
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("[API] Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("[API] Error response: \(responseString)")
            
            if let errorData = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                let errorMessage = errorData.errors.first?.detail ?? "Unknown API error"
                throw APIError.apiError(errorMessage)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        print("[API] Request successful ✅")
        return try JSONDecoder().decode(responseType, from: data)
    }
    
    // MARK: - 设备管理
    func registerDevice(udid: String, name: String, platform: DevicePlatform = .iOS) async throws -> Device {
        let deviceData = DeviceCreateRequest.Data(
            type: "devices",
            attributes: DeviceCreateRequest.Attributes(
                name: name,
                udid: udid,
                platform: platform
            )
        )
        
        let request = DeviceCreateRequest(data: deviceData)
        let requestData = try JSONEncoder().encode(request)
        
        let response: DeviceResponse = try await makeRequest(
            endpoint: "/v1/devices",
            method: "POST",
            body: requestData,
            responseType: DeviceResponse.self
        )
        
        return response.data
    }
    
    func listDevices() async throws -> [Device] {
        let response: DevicesResponse = try await makeRequest(
            endpoint: "/v1/devices",
            responseType: DevicesResponse.self
        )
        
        return response.data
    }
    
    func findDevice(udid: String) async throws -> Device? {
        let devices = try await listDevices()
        return devices.first { $0.attributes.udid == udid }
    }
    
    // MARK: - 证书管理
    func listCertificates(type: AppleCertificateType? = nil) async throws -> [AppleCertificate] {
        var endpoint = "/v1/certificates"
        if let type = type {
            endpoint += "?filter[certificateType]=\(type.rawValue)"
        }
        
        let response: AppleCertificatesResponse = try await makeRequest(
            endpoint: endpoint,
            responseType: AppleCertificatesResponse.self
        )
        
        return response.data
    }
    
    // MARK: - Bundle ID管理
    func listBundleIds() async throws -> [BundleId] {
        let response: BundleIdsResponse = try await makeRequest(
            endpoint: "/v1/bundleIds",
            responseType: BundleIdsResponse.self
        )
        
        return response.data
    }
    
    func findBundleId(identifier: String) async throws -> BundleId? {
        let bundleIds = try await listBundleIds()
        return bundleIds.first { $0.attributes.identifier == identifier }
    }
    
    // MARK: - Provisioning Profile管理
    func listProvisioningProfiles(bundleId: String? = nil) async throws -> [ProvisioningProfile] {
        var endpoint = "/v1/profiles"
        if let bundleId = bundleId {
            endpoint += "?filter[bundleId]=\(bundleId)"
        }
        
        let response: ProvisioningProfilesResponse = try await makeRequest(
            endpoint: endpoint,
            responseType: ProvisioningProfilesResponse.self
        )
        
        return response.data
    }
    
    func createProvisioningProfile(
        name: String,
        bundleId: String,
        certificateIds: [String],
        deviceIds: [String],
        profileType: ProvisioningProfileType = .development
    ) async throws -> ProvisioningProfile {
        let relationships = ProvisioningProfileCreateRequest.Relationships(
            bundleId: .init(data: .init(type: "bundleIds", id: bundleId)),
            certificates: .init(data: certificateIds.map { .init(type: "certificates", id: $0) }),
            devices: .init(data: deviceIds.map { .init(type: "devices", id: $0) })
        )
        
        let profileData = ProvisioningProfileCreateRequest.Data(
            type: "profiles",
            attributes: .init(name: name, profileType: profileType),
            relationships: relationships
        )
        
        let request = ProvisioningProfileCreateRequest(data: profileData)
        let requestData = try JSONEncoder().encode(request)
        
        let response: ProvisioningProfileResponse = try await makeRequest(
            endpoint: "/v1/profiles",
            method: "POST",
            body: requestData,
            responseType: ProvisioningProfileResponse.self
        )
        
        return response.data
    }
}

// MARK: - 数据模型
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

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidPrivateKey
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .invalidPrivateKey:
            return "无效的私钥"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}

struct APIErrorResponse: Codable {
    let errors: [APIErrorDetail]
}

struct APIErrorDetail: Codable {
    let detail: String
}

// MARK: - 设备相关模型
enum DevicePlatform: String, Codable, CaseIterable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
}

struct Device: Codable, Identifiable {
    let id: String
    let type: String
    let attributes: DeviceAttributes
}

struct DeviceAttributes: Codable {
    let name: String
    let udid: String
    let platform: DevicePlatform
    let status: String
    let model: String?
    let deviceClass: String?
}

struct DeviceResponse: Codable {
    let data: Device
}

struct DevicesResponse: Codable {
    let data: [Device]
}

struct DeviceCreateRequest: Codable {
    let data: Data
    
    struct Data: Codable {
        let type: String
        let attributes: Attributes
    }
    
    struct Attributes: Codable {
        let name: String
        let udid: String
        let platform: DevicePlatform
    }
}

// MARK: - 证书相关模型
enum AppleCertificateType: String, Codable, CaseIterable {
    case development = "IOS_DEVELOPMENT"
    case distribution = "IOS_DISTRIBUTION"
    case macDevelopment = "MAC_APP_DEVELOPMENT"
    case macDistribution = "MAC_APP_DISTRIBUTION"
}

struct AppleCertificate: Codable, Identifiable {
    let id: String
    let type: String
    let attributes: AppleCertificateAttributes
}

struct AppleCertificateAttributes: Codable {
    let name: String
    let certificateType: AppleCertificateType
    let displayName: String
    let serialNumber: String
    let platform: String
}

struct AppleCertificatesResponse: Codable {
    let data: [AppleCertificate]
}

// MARK: - Bundle ID相关模型
struct BundleId: Codable, Identifiable {
    let id: String
    let type: String
    let attributes: BundleIdAttributes
}

struct BundleIdAttributes: Codable {
    let identifier: String
    let name: String
    let platform: String
    let seedId: String?
}

struct BundleIdsResponse: Codable {
    let data: [BundleId]
}

// MARK: - Provisioning Profile相关模型
enum ProvisioningProfileType: String, Codable, CaseIterable {
    case development = "IOS_APP_DEVELOPMENT"
    case adHoc = "IOS_APP_ADHOC"
    case appStore = "IOS_APP_STORE"
    case enterprise = "IOS_APP_INHOUSE"
}

struct ProvisioningProfile: Codable, Identifiable {
    let id: String
    let type: String
    let attributes: ProvisioningProfileAttributes
}

struct ProvisioningProfileAttributes: Codable {
    let name: String
    let uuid: String
    let platform: String
    let profileType: ProvisioningProfileType
    let profileContent: String
    let expirationDate: String
    let profileState: String
}

struct ProvisioningProfileResponse: Codable {
    let data: ProvisioningProfile
}

struct ProvisioningProfilesResponse: Codable {
    let data: [ProvisioningProfile]
}

struct ProvisioningProfileCreateRequest: Codable {
    let data: Data
    
    struct Data: Codable {
        let type: String
        let attributes: Attributes
        let relationships: Relationships
    }
    
    struct Attributes: Codable {
        let name: String
        let profileType: ProvisioningProfileType
    }
    
    struct Relationships: Codable {
        let bundleId: BundleIdRelationship
        let certificates: CertificatesRelationship
        let devices: DevicesRelationship
    }
    
    struct BundleIdRelationship: Codable {
        let data: ResourceReference
    }
    
    struct CertificatesRelationship: Codable {
        let data: [ResourceReference]
    }
    
    struct DevicesRelationship: Codable {
        let data: [ResourceReference]
    }
    
    struct ResourceReference: Codable {
        let type: String
        let id: String
    }
}

// MARK: - Data Extensions
extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}