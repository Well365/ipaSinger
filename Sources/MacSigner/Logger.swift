import Foundation

enum Log {
    static func info(_ s: String)  { print("[INFO]", s) }
    static func warn(_ s: String)  { print("[WARN]", s) }
    static func error(_ s: String) { fputs("[ERROR] \(s)\n", stderr) }
}
