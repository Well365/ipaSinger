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
        
        print("[DEBUG] NSTextField created: \(textField)")
        print("[DEBUG] isEnabled: \(textField.isEnabled)")
        print("[DEBUG] isEditable: \(textField.isEditable)")
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
            print("[DEBUG] NSTextField updated to: '\(text)'")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NSTextFieldWrapper
        
        init(_ parent: NSTextFieldWrapper) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let newValue = textField.stringValue
            print("[SUCCESS] ✓ NSTextField text changed: '\(parent.text)' -> '\(newValue)'")
            parent.text = newValue
            print("[SUCCESS] ✓ Binding updated successfully!")
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            print("[INFO] ✓ NSTextField began editing - Focus received!")
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            print("[INFO] ✓ NSTextField ended editing - Final value: '\(textField.stringValue)'")
        }
    }
}

