import Foundation

struct App {
    static func main() async {
        let config = Config.load()
        let api = APIClient(config: config)
        let fastlaneDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("fastlane")
        let executor: SignExecutor = FastlaneSignExecutor(fastlaneDir: fastlaneDir)

        Log.info("MacSigner started. Pool=\(config.serverBaseURL.absoluteString) interval=\(config.pollIntervalSec)s")

        if let cred = KeychainStore.loadCredential() {
            do {
                try await executor.ensureLogin(credential: cred)
                Log.info("Credential OK for \(cred.appleId)")
            } catch {
                Log.error("Credential invalid: \(error)")
            }
        } else if let appleId = ProcessInfo.processInfo.environment["APPLE_ID"] {
            let cred = LoginCredential(appleId: appleId,
                                       sessionToken: ProcessInfo.processInfo.environment["SESSION_TOKEN"],
                                       p12Path: ProcessInfo.processInfo.environment["P12_PATH"],
                                       p12Password: ProcessInfo.processInfo.environment["P12_PASSWORD"])
            do { try KeychainStore.saveCredential(cred); Log.info("Saved credential for \(appleId)") }
            catch { Log.error("Save credential failed: \(error)") }
        } else {
            Log.warn("No credential in Keychain. Set APPLE_ID env on first run to import.")
        }

        while true {
            do {
                if let task = try await api.fetchOneTask() {
                    Log.info("Got task \(task.taskId) ipaId=\(task.ipaId) udid=\(task.udid)")
                    try await api.reportStatus(taskId: task.taskId, status: .running)

                    try await executor.registerUDID(task.udid, bundleId: task.bundleId)
                    let ipaURL = try await executor.resignIPA(ipaId: task.ipaId, options: task.resignOptions)

                    try await api.uploadResult(taskId: task.taskId, downloadURL: "https://cdn.example.com/ipa/\(ipaURL.lastPathComponent)")
                    try await api.reportStatus(taskId: task.taskId, status: .success, message: "OK")
                    Log.info("Task \(task.taskId) done.")
                } else {
                    Log.info("No task. Sleeping \(config.pollIntervalSec)s...")
                    try await Task.sleep(nanoseconds: UInt64(config.pollIntervalSec) * 1_000_000_000)
                }
            } catch {
                Log.error("Loop error: \(error)")
                try? await Task.sleep(nanoseconds: UInt64(config.pollIntervalSec) * 1_000_000_000)
            }
        }
    }
}

// 程序入口点
Task {
    await App.main()
}
