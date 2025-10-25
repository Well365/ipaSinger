import Foundation
import Security

final class KeychainStore {
    static let service = "com.yourorg.MacSigner"

    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: "Keychain", code: Int(status)) }
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func saveCredential(_ cred: LoginCredential) throws {
        let data = try JSONEncoder().encode(cred)
        try save(key: "LoginCredential", data: data)
    }

    static func loadCredential() -> LoginCredential? {
        guard let data = load(key: "LoginCredential") else { return nil }
        return try? JSONDecoder().decode(LoginCredential.self, from: data)
    }
}
