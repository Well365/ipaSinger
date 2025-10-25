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
    let p12Path: String?
    let p12Password: String?
}
