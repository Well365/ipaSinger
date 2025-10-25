import Foundation

protocol SignExecutor {
    func ensureLogin(credential: LoginCredential) async throws
    func registerUDID(_ udid: String, bundleId: String) async throws
    func resignIPA(ipaId: String, options: ResignOptions?) async throws -> URL
    func resignLocalIPA(ipaPath: String, options: ResignOptions?) async throws -> URL
}

enum SignError: Error { case notImplemented, missingCredential }
