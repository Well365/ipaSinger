import Foundation

final class FastlaneSignExecutor: SignExecutor {
    private let fastlaneDir: URL
    private let bundleExec: String

    init(fastlaneDir: URL) {
        self.fastlaneDir = fastlaneDir
        self.bundleExec = "/usr/bin/env"
    }

    private func baseEnv(credential: LoginCredential?) -> [String: String] {
        var env: [String: String] = [
            "LANG": "en_US.UTF-8",
            "LC_ALL": "en_US.UTF-8",
            "FASTLANE_DISABLE_COLORS": "1",
            "FASTLANE_SKIP_UPDATE_CHECK": "1",
            "FASTLANE_OPT_OUT_USAGE": "1"
        ]
        if let cred = credential {
            if let token = cred.sessionToken, !token.isEmpty {
                env["FASTLANE_SESSION"] = token
            } else {
                env["FASTLANE_USER"] = cred.appleId
                if let p = cred.p12Password, !p.isEmpty {
                    env["FASTLANE_PASSWORD"] = p
                }
            }
        }
        return env
    }

    func ensureLogin(credential: LoginCredential) async throws {
        let env = baseEnv(credential: credential)
        let args = ["bundle", "exec", "fastlane", "login"]
        let res = try ProcessRunner.run(bundleExec, args, env: env, cwd: fastlaneDir) { Log.info($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard res.exitCode == 0 else { throw SignError.notImplemented }
    }

    func registerUDID(_ udid: String, bundleId: String) async throws {
        guard let cred = KeychainStore.loadCredential() else { throw SignError.missingCredential }
        var env = baseEnv(credential: cred)
        env["UDID"] = udid
        env["BUNDLE_ID"] = bundleId
        env["AUTO_SIGH"] = "0"
        let args = ["bundle", "exec", "fastlane", "register_udid"]
        let res = try ProcessRunner.run(bundleExec, args, env: env, cwd: fastlaneDir) { Log.info($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard res.exitCode == 0 else { throw SignError.notImplemented }
    }

    func resignIPA(ipaId: String, options: ResignOptions?) async throws -> URL {
        guard let cred = KeychainStore.loadCredential() else { throw SignError.missingCredential }
        var env = baseEnv(credential: cred)
        let localIPA = URL(fileURLWithPath: "/tmp/\(ipaId).ipa")
        env["IPA_PATH"]  = localIPA.path
        env["BUNDLE_ID"] = options?.newBundleId ?? "com.example.app"
        if let team = options?.teamId { env["TEAM_ID"] = team }
        if let pp = options?.provisioningProfileId, !pp.isEmpty {
            env["PP_PATH"] = pp
        }
        let args = ["bundle", "exec", "fastlane", "resign_ipa"]
        let res = try ProcessRunner.run(bundleExec, args, env: env, cwd: fastlaneDir) { Log.info($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard res.exitCode == 0 else { throw SignError.notImplemented }

        let out = res.stdout + "\n" + res.stderr
        guard let line = out.split(separator: "\n").first(where: { $0.contains("RESIGNED_IPA_PATH=") }),
              let path = line.split(separator: "=").last
        else { throw SignError.notImplemented }
        return URL(fileURLWithPath: String(path))
    }
}
