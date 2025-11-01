import SwiftUI
import AppKit

class OverlayWindow: NSWindow, NSWindowDelegate {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    init() {
        super.init(
            contentRect: NSRect(x: Int(SettingsManager.shared.windowPositionX), y: Int(SettingsManager.shared.windowPositionY), width: Int(SettingsManager.shared.windowWidth), height: Int(SettingsManager.shared.windowHeight)),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        // 提升窗口层级，确保在全屏应用上方显示
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.hasShadow = true
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
        self.hidesOnDeactivate = false
        // 关闭系统背景拖动，避免与自定义缩放冲突
        self.isMovableByWindowBackground = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.styleMask.insert(.fullSizeContentView)
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.delegate = self
        
        // 采用系统标准的边缘缩放，无需自定义手柄
    }
    
    // 定义边缘区域类型
    enum ResizeEdge {
        case none, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
    }
    
    // 鼠标移动时更新光标样式
    override func mouseMoved(with event: NSEvent) {
        let edge = resizeEdgeForPoint(event.locationInWindow)
        updateCursorForEdge(edge)
    }
    
    // 鼠标离开窗口时重置光标
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
    // 根据鼠标位置判断所在的边缘区域（窗口坐标系）
    func resizeEdgeForPoint(_ point: NSPoint) -> ResizeEdge {
        let edgeSize: CGFloat = 10.0 // 边缘敏感区域大小
        let size = frame.size
        let isBottom = point.y < edgeSize
        let isTop = point.y > size.height - edgeSize
        // 仅允许垂直方向缩放：顶部或底部
        if isTop { return .top }
        if isBottom { return .bottom }
        return .none
    }
    
    // 根据边缘区域设置对应的光标样式
    func updateCursorForEdge(_ edge: ResizeEdge) {
        switch edge {
        case .top, .bottom:
            NSCursor.resizeUpDown.set()
        default:
            NSCursor.arrow.set()
        }
    }
    
    // 点击时根据位置执行缩放或拖动
    override func mouseDown(with event: NSEvent) {
        let edge = resizeEdgeForPoint(event.locationInWindow)
        // 支持双击退出（仅在非边缘区域触发，避免与缩放冲突）
        if event.clickCount >= 2 && edge == .none {
            NSApplication.shared.terminate(nil)
            return
        }
        if edge != .none {
            // 边缘区域：执行窗口缩放
            resizeWindow(from: edge)
        } else {
            // 非边缘区域：执行拖动并保存位置
            self.performDrag(with: event)
            let newOrigin = frame.origin
            DispatchQueue.main.async {
                SettingsManager.shared.windowPositionX = Double(newOrigin.x)
                SettingsManager.shared.windowPositionY = Double(newOrigin.y)
                SettingsManager.shared.saveSettings()
            }
        }
    }
    
    // 执行窗口缩放（使用窗口坐标系）
    func resizeWindow(from edge: ResizeEdge) {
        let startFrame = frame
        let minSize = NSSize(width: 200, height: 50)
        var tracking = true
        
        while tracking {
            if let mouseEvent = self.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) {
                switch mouseEvent.type {
                case .leftMouseUp:
                    tracking = false
                case .leftMouseDragged:
                    let p = mouseEvent.locationInWindow // 相对窗口坐标
                    var newFrame = startFrame
                    // 固定宽度，不允许改变X与宽度
                    newFrame.origin.x = startFrame.origin.x
                    newFrame.size.width = startFrame.size.width

                    switch edge {
                    case .top:
                        newFrame.size.height = max(p.y, minSize.height)
                    case .bottom:
                        let newHeight = max(startFrame.size.height - p.y, minSize.height)
                        newFrame.origin.y = startFrame.maxY - newHeight
                        newFrame.size.height = newHeight
                    default:
                        break
                    }
                    
                    setFrame(newFrame, display: true)
                    
                    // 保存新的窗口位置和尺寸
                    DispatchQueue.main.async {
                        SettingsManager.shared.windowPositionX = Double(newFrame.origin.x)
                        SettingsManager.shared.windowPositionY = Double(newFrame.origin.y)
                        SettingsManager.shared.windowWidth = Double(newFrame.size.width)
                        SettingsManager.shared.windowHeight = Double(newFrame.size.height)
                        SettingsManager.shared.saveSettings()
                    }
                default:
                    break
                }
            }
        }
    }

    // 限制系统侧的缩放行为：锁定宽度，仅允许高度变化
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let fixedWidth = self.frame.size.width
        let newHeight = max(frameSize.height, 50.0)
        return NSSize(width: fixedWidth, height: newHeight)
    }
    
    // 移动与缩放时保存位置与尺寸
    func windowDidMove(_ notification: Notification) {
        let origin = frame.origin
        DispatchQueue.main.async {
            SettingsManager.shared.windowPositionX = Double(origin.x)
            SettingsManager.shared.windowPositionY = Double(origin.y)
            SettingsManager.shared.saveSettings()
        }
    }
    
    func windowDidResize(_ notification: Notification) {
        // Update stored size
        DispatchQueue.main.async {
            SettingsManager.shared.windowWidth = Double(self.frame.width)
            SettingsManager.shared.windowHeight = Double(self.frame.height)
            SettingsManager.shared.saveSettings()
        }
    }
}

class OverlayWindowController: NSWindowController {
    static var shared: OverlayWindowController?
    
    convenience init() {
        // 如果尚未应用“默认全屏宽度”，则先更新一次宽度（高度保持不变，固定为上一次保存的高度）
        let sizeDefaultAppliedKey = "SizeDefaultApplied"
        let applied = UserDefaults.standard.bool(forKey: sizeDefaultAppliedKey)
        if !applied {
            let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: SettingsManager.shared.windowWidth, height: SettingsManager.shared.windowHeight)
            let newWidth = Double(visibleFrame.width)
            SettingsManager.shared.windowWidth = newWidth
            // 让窗口从屏幕左侧开始，纵向位置保持用户上次设置
            SettingsManager.shared.windowPositionX = Double(visibleFrame.minX)
            SettingsManager.shared.saveSettings()
            UserDefaults.standard.set(true, forKey: sizeDefaultAppliedKey)
        }

        // 首次运行或未应用时，将透明度设为不透明（1.0）
        let opacityDefaultAppliedKey = "OpacityDefaultApplied"
        if !UserDefaults.standard.bool(forKey: opacityDefaultAppliedKey) {
            SettingsManager.shared.transparency = 1.0
            SettingsManager.shared.saveSettings()
            UserDefaults.standard.set(true, forKey: opacityDefaultAppliedKey)
        }

        // 应用户需求：一次性把高度设置为90（若未应用过）
        let height90AppliedKey = "UserRequestedHeight90Applied"
        if !UserDefaults.standard.bool(forKey: height90AppliedKey) {
            SettingsManager.shared.windowHeight = 90
            SettingsManager.shared.saveSettings()
            UserDefaults.standard.set(true, forKey: height90AppliedKey)
        }

        let overlayView = OverlayView()
            .frame(width: SettingsManager.shared.windowWidth, height: SettingsManager.shared.windowHeight)

        let hostingController = NSHostingController(rootView: overlayView)
        let window = OverlayWindow()
        window.contentViewController = hostingController
        window.setFrame(NSRect(
            x: SettingsManager.shared.windowPositionX,
            y: SettingsManager.shared.windowPositionY,
            width: SettingsManager.shared.windowWidth,
            height: SettingsManager.shared.windowHeight
        ), display: true)
        
        self.init(window: window)
        OverlayWindowController.shared = self
        
        // Update the overlay with current settings
        updateOverlayColor(SettingsManager.shared.overlayColor)
        updateOverlayTransparency(SettingsManager.shared.transparency)
    }
    
    func updateOverlayColor(_ color: Color) {
        guard let hostingController = window?.contentViewController as? NSHostingController<OverlayView> else { return }
        hostingController.rootView.overlayColor = color
    }
    
    func updateOverlayTransparency(_ transparency: Double) {
        guard let hostingController = window?.contentViewController as? NSHostingController<OverlayView> else { return }
        hostingController.rootView.transparency = transparency
    }
}