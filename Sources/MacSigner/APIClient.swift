import Foundation

final class APIClient {
    let base: URL
    let token: String
    let session = URLSession(configuration: .default)

    init(config: Config) {
        self.base = config.serverBaseURL
        self.token = config.apiToken
    }

    private func request(_ path: String,
                         method: String = "GET",
                         body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        var url = base
        url.append(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = body

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "API", code: http.statusCode,
                          userInfo: ["body": String(data: data, encoding: .utf8) ?? ""])
        }
        return (data, http)
    }

    func fetchOneTask() async throws -> SignTask? {
        let (data, _) = try await request("/api/signer/next")
        if data.isEmpty { return nil }
        return try JSONDecoder().decode(SignTask?.self, from: data)
    }

    func reportStatus(taskId: String, status: TaskStatus, message: String? = nil) async throws {
        struct Payload: Codable { let status: TaskStatus; let message: String? }
        let payload = Payload(status: status, message: message)
        let body = try JSONEncoder().encode(payload)
        _ = try await request("/api/signer/\(taskId)/status", method: "POST", body: body)
    }

    func uploadResult(taskId: String, downloadURL: String) async throws {
        struct Payload: Codable { let downloadURL: String }
        let body = try JSONEncoder().encode(Payload(downloadURL: downloadURL))
        _ = try await request("/api/signer/\(taskId)/result", method: "POST", body: body)
    }
}
