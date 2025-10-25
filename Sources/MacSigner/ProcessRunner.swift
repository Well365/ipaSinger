import Foundation

struct ProcessResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

enum ProcessRunner {
    static func run(_ launchPath: String,
                    _ args: [String],
                    env: [String: String] = [:],
                    cwd: URL? = nil,
                    tee: ((String) -> Void)? = nil) throws -> ProcessResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = args
        if let cwd { task.currentDirectoryURL = cwd }

        var fullEnv = ProcessInfo.processInfo.environment
        env.forEach { fullEnv[$0.key] = $0.value }
        task.environment = fullEnv

        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe

        try task.run()

        var outData = Data()
        var errData = Data()

        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading

        while task.isRunning {
            if let chunk = try? outHandle.read(upToCount: 4096), !chunk.isEmpty {
                outData.append(chunk)
                if let s = String(data: chunk, encoding: .utf8) { tee?(s) }
            }
            if let chunk = try? errHandle.read(upToCount: 4096), !chunk.isEmpty {
                errData.append(chunk)
                if let s = String(data: chunk, encoding: .utf8) { tee?(s) }
            }
            usleep(50_000)
        }

        let remOut = outHandle.readDataToEndOfFile()
        outData.append(remOut)
        if let s = String(data: remOut, encoding: .utf8) { tee?(s) }

        let remErr = errHandle.readDataToEndOfFile()
        errData.append(remErr)
        if let s = String(data: remErr, encoding: .utf8) { tee?(s) }

        let code = task.terminationStatus
        return ProcessResult(exitCode: code,
                             stdout: String(data: outData, encoding: .utf8) ?? "",
                             stderr: String(data: errData, encoding: .utf8) ?? "")
    }
}
