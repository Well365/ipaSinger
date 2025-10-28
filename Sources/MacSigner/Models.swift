import Foundation

enum TaskStatus: String, Codable {
    case queued, running, success, failed, returned
}

struct SignTask: Codable {
    let taskId: String
    let ipaId: String
    let udid: String
    let bundleId: String
    let minOS: String?
    let resignOptions: ResignOptions?
}

struct ResignOptions: Codable {
    let provisioningProfileId: String?
    let teamId: String?
    let newBundleId: String?
}

struct LoginCredential: Codable {
    let appleId: String
    let sessionToken: String?
    let sessionExpiryDate: Date?
    let p12Path: String?
    let p12Password: String?
    
    init(appleId: String, sessionToken: String? = nil, sessionExpiryDate: Date? = nil, p12Path: String? = nil, p12Password: String? = nil) {
        self.appleId = appleId
        self.sessionToken = sessionToken
        self.sessionExpiryDate = sessionExpiryDate
        self.p12Path = p12Path
        self.p12Password = p12Password
    }
}

struct DeveloperCertificate: Identifiable, Hashable {
    let id: String
    let name: String
    let type: CertificateType
    
    var displayName: String {
        // 简化显示名称，避免过长
        let shortName = name.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? name
        return "\(type.displayName): \(shortName)"
    }
    
    var shortDisplayName: String {
        // 更短的显示名称用于下拉菜单
        let shortName = name.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? name
        return shortName
    }
}

enum CertificateType: String, CaseIterable {
    case iosDevelopment = "iOS Development"
    case appleDevelopment = "Apple Development"
    case macDevelopment = "Mac Development"
    case iosDistribution = "iOS Distribution"
    case appleDistribution = "Apple Distribution"
    case macDistribution = "Mac Distribution"
    case unknown = "Unknown"
    
    var displayName: String {
        return self.rawValue
    }
    
    var isDevelopment: Bool {
        return self == .iosDevelopment || self == .appleDevelopment || self == .macDevelopment
    }
}
