import Cocoa
import SwiftUI

class LocalSignWindowController: NSWindowController {
    private var signerManager: SignerManager
    
    init(signerManager: SignerManager) {
        self.signerManager = signerManager
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        window.title = "本地IPA签名"
        window.center()
        window.isReleasedWhenClosed = false
        
        // 使用SwiftUI视图
        let contentView = LocalSignView()
            .environmentObject(signerManager)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = window.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        
        print("[DEBUG] LocalSignWindowController initialized")
        print("[DEBUG] Window: \(window)")
        print("[DEBUG] ContentView: \(String(describing: window.contentView))")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        print("[DEBUG] Showing window...")
        
        // 强制激活应用到前台
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // 显示窗口
        window?.makeKeyAndOrderFront(nil)
        
        // 多次尝试确保焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKey()
            self.window?.orderFrontRegardless()
            
            print("[DEBUG] First activation attempt")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 再次强制激活
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKey()
            
            // 尝试让第一个TextField获得焦点
            if let contentView = self.window?.contentView {
                self.window?.makeFirstResponder(contentView)
            }
            
            print("[DEBUG] Window shown and activated")
            print("[DEBUG] Is key window: \(self.window?.isKeyWindow ?? false)")
            print("[DEBUG] Is main window: \(self.window?.isMainWindow ?? false)")
            print("[DEBUG] NSApp.isActive: \(NSApp.isActive)")
            print("[DEBUG] NSApp.keyWindow: \(String(describing: NSApp.keyWindow))")
            print("[DEBUG] NSApp.mainWindow: \(String(describing: NSApp.mainWindow))")
        }
    }
}

