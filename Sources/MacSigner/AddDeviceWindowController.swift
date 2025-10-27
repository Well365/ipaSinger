import SwiftUI
import AppKit

class AddDeviceWindowController: NSWindowController {
    
    init() {
        let addDeviceView = AddDeviceView()
        let hostingController = NSHostingController(rootView: addDeviceView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 650),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "设备管理"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("AddDeviceWindow")
        
        // 设置最小尺寸
        window.minSize = NSSize(width: 600, height: 500)
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}