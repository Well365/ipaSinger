import Foundation

struct Config {
    let serverBaseURL: URL
    let apiToken: String
    let pollIntervalSec: Int

    static func load() -> Config {
        let base = ProcessInfo.processInfo.environment["POOL_BASE_URL"] ?? "https://pool.example.com"
        let token = ProcessInfo.processInfo.environment["POOL_API_TOKEN"] ?? "dev-token"
        let interval = Int(ProcessInfo.processInfo.environment["POLL_INTERVAL"] ?? "10") ?? 10
        return Config(serverBaseURL: URL(string: base)!, apiToken: token, pollIntervalSec: interval)
    }
}
