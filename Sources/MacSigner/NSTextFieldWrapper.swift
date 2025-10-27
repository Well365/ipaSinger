import SwiftUI
import AppKit

/// 原生NSTextField包装器，解决SwiftUI TextField在某些情况下无法输入的问题
struct NSTextFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    
    func makeNSView(context: Context) -> NSTextField {
        let textField: NSTextField
        
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        
        // 确保可以接收焦点和输入
        textField.isEnabled = true
        textField.isEditable = true
        textField.isSelectable = true
        
        // 设置字体和外观
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.textColor = NSColor.labelColor
        
        print("[DEBUG] NSTextField created: \(textField)")
        print("[DEBUG] isEnabled: \(textField.isEnabled)")
        print("[DEBUG] isEditable: \(textField.isEditable)")
        print("[DEBUG] acceptsFirstResponder: \(textField.acceptsFirstResponder)")
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // 只在值真正不同时更新，避免循环更新
        if nsView.stringValue != text {
            nsView.stringValue = text
            print("[DEBUG] NSTextField updated to: '\(text)'")
        }
        
        // 确保文本框保持可编辑状态
        if !nsView.isEditable {
            nsView.isEditable = true
            nsView.isEnabled = true
            print("[DEBUG] Re-enabled NSTextField editing")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NSTextFieldWrapper
        
        init(_ parent: NSTextFieldWrapper) {
            self.parent = parent
            super.init()
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let newValue = textField.stringValue
            
            // 防止循环更新
            if parent.text != newValue {
                print("[SUCCESS] ✓ NSTextField text changed: '\(parent.text)' -> '\(newValue)'")
                DispatchQueue.main.async {
                    self.parent.text = newValue
                }
                print("[SUCCESS] ✓ Binding updated successfully!")
            }
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            print("[INFO] ✓ NSTextField began editing - Focus received!")
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            print("[INFO] ✓ NSTextField ended editing - Final value: '\(textField.stringValue)'")
            
            // 确保最终值同步
            DispatchQueue.main.async {
                if self.parent.text != textField.stringValue {
                    self.parent.text = textField.stringValue
                }
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // 处理特殊按键，如回车键
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // 回车键被按下，结束编辑
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

