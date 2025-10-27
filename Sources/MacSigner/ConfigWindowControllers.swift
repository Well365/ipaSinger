import Cocoa
import SwiftUI

class AppleCredentialWindowController: NSWindowController {
    private var signerManager: SignerManager
    
    init(signerManager: SignerManager) {
        self.signerManager = signerManager
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        window.title = "Apple ID 配置"
        window.center()
        window.isReleasedWhenClosed = false
        
        // 使用SwiftUI视图
        let contentView = AppleCredentialView()
            .environmentObject(signerManager)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = window.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        
        print("[DEBUG] AppleCredentialWindowController initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        print("[DEBUG] Showing Apple Credential window...")
        
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
            
            print("[DEBUG] Apple Credential window activation attempt")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 再次强制激活
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKey()
            
            // 尝试让第一个TextField获得焦点
            if let contentView = self.window?.contentView {
                self.window?.makeFirstResponder(contentView)
            }
            
            print("[DEBUG] Apple Credential window shown and activated")
            print("[DEBUG] Is key window: \(self.window?.isKeyWindow ?? false)")
        }
    }
}

class ServerConfigWindowController: NSWindowController {
    private var signerManager: SignerManager
    
    init(signerManager: SignerManager) {
        self.signerManager = signerManager
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        window.title = "服务器配置"
        window.center()
        window.isReleasedWhenClosed = false
        
        // 使用SwiftUI视图
        let contentView = ServerConfigView()
            .environmentObject(signerManager)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = window.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        
        print("[DEBUG] ServerConfigWindowController initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        print("[DEBUG] Showing Server Config window...")
        
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
            
            print("[DEBUG] Server Config window activation attempt")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 再次强制激活
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKey()
            
            // 尝试让第一个TextField获得焦点
            if let contentView = self.window?.contentView {
                self.window?.makeFirstResponder(contentView)
            }
            
            print("[DEBUG] Server Config window shown and activated")
            print("[DEBUG] Is key window: \(self.window?.isKeyWindow ?? false)")
        }
    }
}