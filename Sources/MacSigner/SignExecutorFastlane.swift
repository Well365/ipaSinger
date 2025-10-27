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
        print("[DEBUG] FastlaneSignExecutor.ensureLogin 开始")
        print("[DEBUG] 凭证: \(credential.appleId)")
        
        let env = baseEnv(credential: credential)
        print("[DEBUG] 环境变量:")
        for (key, value) in env.sorted(by: { $0.key < $1.key }) {
            if key.contains("PASSWORD") || key.contains("SESSION") {
                print("[DEBUG]   \(key) = [HIDDEN]")
            } else {
                print("[DEBUG]   \(key) = \(value)")
            }
        }
        
        let args = ["bundle", "exec", "fastlane", "login"]
        print("[DEBUG] 命令: \(bundleExec) \(args.joined(separator: " "))")
        print("[DEBUG] 工作目录: \(fastlaneDir.path)")
        
        let res = try ProcessRunner.run(bundleExec, args, env: env, cwd: fastlaneDir) { output in
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                print("[FASTLANE] \(trimmed)")
            }
        }
        
        print("[DEBUG] 退出代码: \(res.exitCode)")
        if !res.stdout.isEmpty {
            print("[DEBUG] 标准输出:\n\(res.stdout)")
        }
        if !res.stderr.isEmpty {
            print("[DEBUG] 错误输出:\n\(res.stderr)")
        }
        
        guard res.exitCode == 0 else { 
            print("[ERROR] fastlane login 失败，退出代码: \(res.exitCode)")
            throw NSError(domain: "FastlaneLogin", code: Int(res.exitCode), userInfo: [
                NSLocalizedDescriptionKey: "Fastlane登录失败",
                "stdout": res.stdout,
                "stderr": res.stderr
            ])
        }
        print("[SUCCESS] ✓ fastlane login 成功")
    }

    func registerUDID(_ udid: String, bundleId: String) async throws {
        print("[DEBUG] FastlaneSignExecutor.registerUDID 开始")
        print("[DEBUG] UDID: \(udid)")
        print("[DEBUG] Bundle ID: \(bundleId)")
        
        guard let cred = KeychainStore.loadCredential() else { 
            print("[ERROR] 未找到凭证")
            throw SignError.missingCredential 
        }
        
        var env = baseEnv(credential: cred)
        env["UDID"] = udid
        env["BUNDLE_ID"] = bundleId
        env["AUTO_SIGH"] = "0"
        
        print("[DEBUG] 环境变量:")
        for (key, value) in env.sorted(by: { $0.key < $1.key }) {
            if key.contains("PASSWORD") || key.contains("SESSION") {
                print("[DEBUG]   \(key) = [HIDDEN]")
            } else {
                print("[DEBUG]   \(key) = \(value)")
            }
        }
        
        let args = ["bundle", "exec", "fastlane", "register_udid"]
        print("[DEBUG] 命令: \(bundleExec) \(args.joined(separator: " "))")
        print("[DEBUG] 工作目录: \(fastlaneDir.path)")
        
        let res = try ProcessRunner.run(bundleExec, args, env: env, cwd: fastlaneDir) { output in
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                print("[FASTLANE] \(trimmed)")
            }
        }
        
        print("[DEBUG] 退出代码: \(res.exitCode)")
        if !res.stdout.isEmpty {
            print("[DEBUG] 标准输出:\n\(res.stdout)")
        }
        if !res.stderr.isEmpty {
            print("[DEBUG] 错误输出:\n\(res.stderr)")
        }
        
        guard res.exitCode == 0 else {
            print("[ERROR] fastlane register_udid 失败，退出代码: \(res.exitCode)")
            throw NSError(domain: "FastlaneRegisterUDID", code: Int(res.exitCode), userInfo: [
                NSLocalizedDescriptionKey: "设备注册失败",
                "stdout": res.stdout,
                "stderr": res.stderr
            ])
        }
        print("[SUCCESS] ✓ fastlane register_udid 成功")
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
    
    func resignLocalIPA(ipaPath: String, options: ResignOptions?) async throws -> URL {
        print("[DEBUG] FastlaneSignExecutor.resignLocalIPA 开始")
        print("[DEBUG] IPA路径: \(ipaPath)")
        print("[DEBUG] 选项: \(String(describing: options))")
        
        guard let cred = KeychainStore.loadCredential() else { 
            print("[ERROR] 未找到凭证")
            throw SignError.missingCredential 
        }
        
        var env = baseEnv(credential: cred)
        env["IPA_PATH"] = ipaPath
        env["BUNDLE_ID"] = options?.newBundleId ?? "com.example.app"
        if let team = options?.teamId { env["TEAM_ID"] = team }
        if let pp = options?.provisioningProfileId, !pp.isEmpty {
            env["PP_PATH"] = pp
        }
        
        print("[DEBUG] 环境变量:")
        for (key, value) in env.sorted(by: { $0.key < $1.key }) {
            if key.contains("PASSWORD") || key.contains("SESSION") {
                print("[DEBUG]   \(key) = [HIDDEN]")
            } else {
                print("[DEBUG]   \(key) = \(value)")
            }
        }
        
        let args = ["bundle", "exec", "fastlane", "resign_ipa"]
        print("[DEBUG] 命令: \(bundleExec) \(args.joined(separator: " "))")
        print("[DEBUG] 工作目录: \(fastlaneDir.path)")
        
        print("[INFO] 开始执行fastlane重签名命令，这可能需要几分钟...")
        
        let res = try ProcessRunner.run(bundleExec, args, env: env, cwd: fastlaneDir) { output in
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                print("[FASTLANE] \(trimmed)")
            }
        }
        
        print("[DEBUG] 退出代码: \(res.exitCode)")
        if !res.stdout.isEmpty {
            print("[DEBUG] 完整标准输出:\n\(res.stdout)")
        }
        if !res.stderr.isEmpty {
            print("[DEBUG] 完整错误输出:\n\(res.stderr)")
        }
        
        guard res.exitCode == 0 else {
            print("[ERROR] fastlane resign_ipa 失败，退出代码: \(res.exitCode)")
            throw NSError(domain: "FastlaneResignIPA", code: Int(res.exitCode), userInfo: [
                NSLocalizedDescriptionKey: "IPA重签名失败",
                "stdout": res.stdout,
                "stderr": res.stderr
            ])
        }

        let out = res.stdout + "\n" + res.stderr
        print("[DEBUG] 查找输出路径...")
        print("[DEBUG] 输出内容:\n\(out)")
        
        guard let line = out.split(separator: "\n").first(where: { $0.contains("RESIGNED_IPA_PATH=") }),
              let path = line.split(separator: "=").last
        else { 
            print("[ERROR] 未找到RESIGNED_IPA_PATH标记")
            print("[ERROR] 完整输出: \(out)")
            throw NSError(domain: "FastlaneResignIPA", code: 999, userInfo: [
                NSLocalizedDescriptionKey: "无法解析重签名输出路径",
                "output": out
            ])
        }
        
        let outputPath = String(path)
        print("[SUCCESS] ✓ fastlane resign_ipa 成功")
        print("[SUCCESS] 输出路径: \(outputPath)")
        return URL(fileURLWithPath: outputPath)
    }
}
