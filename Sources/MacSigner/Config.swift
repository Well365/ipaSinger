import Foundation

struct Config {
    let serverBaseURL: URL
    let apiToken: String
    let pollIntervalSec: Int
    
    // Apple API配置
    let appleAPIKeyID: String
    let appleAPIIssuerID: String
    let appleAPIPrivateKey: String

    static func load() -> Config {
        let base = ProcessInfo.processInfo.environment["POOL_BASE_URL"] ?? "https://pool.example.com"
        let token = ProcessInfo.processInfo.environment["POOL_API_TOKEN"] ?? "dev-token"
        let interval = Int(ProcessInfo.processInfo.environment["POLL_INTERVAL"] ?? "10") ?? 10
        
        // Apple API配置 - 优先从UserDefaults读取，然后从环境变量
        let keyID = UserDefaults.standard.string(forKey: "AppleAPIKeyID") ?? 
                   ProcessInfo.processInfo.environment["APPLE_API_KEY_ID"] ?? ""
        let issuerID = UserDefaults.standard.string(forKey: "AppleAPIIssuerID") ?? 
                      ProcessInfo.processInfo.environment["APPLE_API_ISSUER_ID"] ?? ""
        let privateKey = UserDefaults.standard.string(forKey: "AppleAPIPrivateKey") ?? 
                        ProcessInfo.processInfo.environment["APPLE_API_PRIVATE_KEY"] ?? ""
        
        return Config(
            serverBaseURL: URL(string: base)!,
            apiToken: token,
            pollIntervalSec: interval,
            appleAPIKeyID: keyID,
            appleAPIIssuerID: issuerID,
            appleAPIPrivateKey: privateKey
        )
    }
}
