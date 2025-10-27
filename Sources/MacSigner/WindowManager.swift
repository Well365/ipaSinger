import SwiftUI
import AppKit

// 全局窗口管理器，用于在不同视图间共享窗口控制器
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var appleAPIConfigWindowController: NSWindowController?
    
    private init() {}
    
    func openAppleAPIConfigWindow() {
        // 如果窗口已存在，直接显示
        if let controller = appleAPIConfigWindowController {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新的配置窗口
        let configView = AppleAPIConfigView()
        let hostingController = NSHostingController(rootView: configView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Apple Developer API 配置"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("AppleAPIConfigWindow")
        
        // 设置最小尺寸
        window.minSize = NSSize(width: 600, height: 500)
        
        let controller = NSWindowController(window: window)
        appleAPIConfigWindowController = controller
        
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}