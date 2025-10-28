# Session Manager 输入修复测试指南

## 修复内容

### 1. 创建了 `SessionManagerWindowController.swift`
- 仿照 `LocalSignWindowController` 的实现
- 包含完整的窗口激活逻辑
- 多次尝试激活以确保窗口获得焦点

### 2. 修改了 `ContentView.swift`
- 将 `sessionManagerWindowController` 类型从 `NSWindowController?` 改为 `SessionManagerWindowController?`
- 简化了 `openSessionManagerWindow()` 方法，使用新的 WindowController

### 3. 优化了 `SessionManagerView.swift`
- 移除了 `.onAppear` 中的延迟焦点设置逻辑
- 焦点管理现在统一由 WindowController 处理

## 关键修复点对比

| 问题 | 修复前 | 修复后 |
|------|--------|--------|
| WindowController | 标准 NSWindowController | 自定义 SessionManagerWindowController |
| styleMask | 缺少 .miniaturizable | 包含完整样式 |
| 内容设置 | contentViewController | contentView (NSHostingView) |
| 窗口激活 | 单次 showWindow | 多次 activate + makeKey |
| FirstResponder | 未设置 | 显式设置 |
| 焦点延迟 | 1秒延迟 | 由WindowController统一处理 |

## 测试步骤

1. **编译项目**
   ```bash
   swift build
   ```

2. **运行应用**
   ```bash
   swift run
   ```

3. **测试输入功能**
   - 点击主界面的 "Session 管理" 按钮
   - 尝试在 "Apple ID" 输入框中输入文字
   - 尝试在 "应用专属密码" 输入框中输入文字
   - 验证是否可以正常输入和编辑

4. **测试焦点切换**
   - 使用 Tab 键在输入框之间切换
   - 验证焦点是否正确移动
   - 验证所有输入框都可以编辑

5. **对比测试**
   - 打开 "本地签名" 窗口
   - 对比输入体验是否一致
   - 验证两个窗口的输入行为相同

## 预期结果

✅ Session Manager 窗口打开后，文本框立即可以接收输入
✅ 点击文本框或使用Tab键可以正常切换焦点
✅ 输入中文、英文、数字都正常显示
✅ 密码框的加密显示功能正常工作
✅ 窗口行为与 LocalSignView 一致

## 技术细节

### 窗口激活序列
```swift
1. NSApp.activate(ignoringOtherApps: true)  // 立即激活
2. window?.makeKeyAndOrderFront(nil)         // 显示窗口
3. [延迟 0.1s] makeKey() + orderFrontRegardless()  // 强制置前
4. [延迟 0.3s] makeKey() + makeFirstResponder()    // 设置焦点
```

### 为什么需要多次激活？
- macOS 的窗口管理系统可能在首次激活时被其他进程干扰
- SwiftUI 的 NSHostingView 需要时间来完成布局
- 多次尝试确保即使在复杂场景下也能获得焦点

### 为什么使用 contentView 而非 contentViewController？
- 直接设置 contentView 可以更好地控制响应链
- NSHostingController 可能会引入额外的响应链层级
- LocalSignView 使用 contentView 方式已验证可行
