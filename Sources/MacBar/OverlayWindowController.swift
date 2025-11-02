import SwiftUI
import AppKit

final class FixedSizeHostingView<Content: View>: NSHostingView<Content> {
    var fixedSize: NSSize = .zero
    override var intrinsicContentSize: NSSize {
        return fixedSize
    }
}

class OverlayWindow: NSWindow, NSWindowDelegate {
    // 启动阶段不保存窗口尺寸，避免系统展示过程的临时变化污染设置
    var savingEnabled: Bool = false
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    init() {
        super.init(
            contentRect: NSRect(x: Int(SettingsManager.shared.windowPositionX), y: Int(SettingsManager.shared.windowPositionY), width: Int(SettingsManager.shared.windowWidth), height: Int(SettingsManager.shared.windowHeight)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        // 提升窗口层级，确保在全屏应用上方显示
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.hasShadow = false // 移除阴影，让它更像一个"贴片"
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
        self.hidesOnDeactivate = false
        // 关闭系统背景拖动，避免与自定义缩放冲突
        self.isMovableByWindowBackground = false
        // 无标题栏窗口，避免标题栏高度影响；设置最小内容尺寸与自定义缩放一致
        self.contentMinSize = NSSize(width: 100, height: 30)
        self.minSize = NSSize(width: 100, height: 30)
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.delegate = self
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
    
    // 支持边缘调节：顶部、底部、左侧、右侧、四个角
    func resizeEdgeForPoint(_ point: NSPoint) -> ResizeEdge {
        let edgeSize: CGFloat = 10.0 // 边缘敏感区域大小
        let size = frame.size
        let isLeft = point.x < edgeSize
        let isRight = point.x > size.width - edgeSize
        let isBottom = point.y < edgeSize
        let isTop = point.y > size.height - edgeSize

        // 判断四个角
        if isTop && isLeft { return .topLeft }
        if isTop && isRight { return .topRight }
        if isBottom && isLeft { return .bottomLeft }
        if isBottom && isRight { return .bottomRight }

        // 判断四条边
        if isTop { return .top }
        if isBottom { return .bottom }
        if isLeft { return .left }
        if isRight { return .right }

        return .none
    }
    
    // 根据边缘区域设置对应的光标样式
    func updateCursorForEdge(_ edge: ResizeEdge) {
        switch edge {
        case .top, .bottom:
            NSCursor.resizeUpDown.set()
        case .left, .right:
            NSCursor.resizeLeftRight.set()
        case .topLeft, .bottomRight, .topRight, .bottomLeft:
            // 角落区域使用对角线缩放光标，如果没有专用光标则使用标准缩放光标
            NSCursor.resizeLeftRight.set() // 或者使用 resizeUpDown
        default:
            NSCursor.arrow.set()
        }
    }
    
    // 点击时根据位置执行缩放或拖动
    override func mouseDown(with event: NSEvent) {
        let edge = resizeEdgeForPoint(event.locationInWindow)
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
        let minSize = NSSize(width: 100, height: 30)
        var tracking = true

        while tracking {
            if let mouseEvent = self.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) {
                switch mouseEvent.type {
                case .leftMouseUp:
                    tracking = false
                case .leftMouseDragged:
                    let p = mouseEvent.locationInWindow // 相对窗口坐标
                    var newFrame = startFrame

                    switch edge {
                    case .top:
                        newFrame.size.height = max(p.y, minSize.height)
                    case .bottom:
                        let newHeight = max(startFrame.size.height - p.y, minSize.height)
                        newFrame.origin.y = startFrame.maxY - newHeight
                        newFrame.size.height = newHeight
                    case .left:
                        let newWidth = max(startFrame.size.width - p.x, minSize.width)
                        newFrame.origin.x = startFrame.maxX - newWidth
                        newFrame.size.width = newWidth
                    case .right:
                        newFrame.size.width = max(p.x, minSize.width)
                    case .topLeft:
                        let newWidth = max(startFrame.size.width - p.x, minSize.width)
                        let newHeight = max(p.y, minSize.height)
                        newFrame.origin.x = startFrame.maxX - newWidth
                        newFrame.size.width = newWidth
                        newFrame.size.height = newHeight
                    case .topRight:
                        let newWidth = max(p.x, minSize.width)
                        let newHeight = max(p.y, minSize.height)
                        newFrame.size.width = newWidth
                        newFrame.size.height = newHeight
                    case .bottomLeft:
                        let newWidth = max(startFrame.size.width - p.x, minSize.width)
                        let newHeight = max(startFrame.size.height - p.y, minSize.height)
                        newFrame.origin.x = startFrame.maxX - newWidth
                        newFrame.origin.y = startFrame.maxY - newHeight
                        newFrame.size.width = newWidth
                        newFrame.size.height = newHeight
                    case .bottomRight:
                        let newWidth = max(p.x, minSize.width)
                        let newHeight = max(startFrame.size.height - p.y, minSize.height)
                        newFrame.origin.y = startFrame.maxY - newHeight
                        newFrame.size.width = newWidth
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

    // 移除限制系统侧的缩放行为，让自定义缩放完全控制
    // func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
    //     let fixedWidth = self.frame.size.width
    //     let newHeight = max(frameSize.height, 50.0)
    //     return NSSize(width: fixedWidth, height: newHeight)
    // }
    
    // 移动与缩放时保存位置与尺寸
    func windowDidMove(_ notification: Notification) {
        let origin = frame.origin
        if savingEnabled {
            DispatchQueue.main.async {
                SettingsManager.shared.windowPositionX = Double(origin.x)
                SettingsManager.shared.windowPositionY = Double(origin.y)
                SettingsManager.shared.saveSettings()
            }
        }
        print("[MacBar] Overlay window did move: origin=\(origin)")
    }
    
    func windowDidResize(_ notification: Notification) {
        // Update stored size
        if savingEnabled {
            DispatchQueue.main.async {
                // 无标题栏下，frame即内容尺寸
                SettingsManager.shared.windowWidth = Double(self.frame.width)
                SettingsManager.shared.windowHeight = Double(self.frame.height)
                SettingsManager.shared.saveSettings()
            }
        }
        print("[MacBar] Overlay window did resize: frame=\(self.frame), content=\(self.contentLayoutRect)")
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

        // 应用户需求：一次性把高度设置为70（若未应用过）
        let height70AppliedKey = "UserRequestedHeight70Applied"
        if !UserDefaults.standard.bool(forKey: height70AppliedKey) {
            SettingsManager.shared.windowHeight = 70
            SettingsManager.shared.saveSettings()
            UserDefaults.standard.set(true, forKey: height70AppliedKey)
        }

        let overlayView = OverlayView()
            .frame(width: SettingsManager.shared.windowWidth, height: SettingsManager.shared.windowHeight)
            .fixedSize()

        let hostingView = FixedSizeHostingView(rootView: overlayView)
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.fixedSize = NSSize(width: SettingsManager.shared.windowWidth, height: SettingsManager.shared.windowHeight)
        hostingView.setFrameSize(hostingView.fixedSize)
        let window = OverlayWindow()
        window.contentView = hostingView
        // 以内容尺寸为准直接设置窗口frame（无标题栏时frame即内容尺寸）
        let contentRect = NSRect(
            x: SettingsManager.shared.windowPositionX,
            y: SettingsManager.shared.windowPositionY,
            width: SettingsManager.shared.windowWidth,
            height: SettingsManager.shared.windowHeight
        )
        window.setFrame(contentRect, display: true)
        
        self.init(window: window)
        OverlayWindowController.shared = self
        // 初始尺寸已设置，允许后续交互保存尺寸
        window.savingEnabled = true
        
        // Update the overlay with current settings
        updateOverlayColor(SettingsManager.shared.overlayColor)
        updateOverlayTransparency(SettingsManager.shared.transparency)
    }
    
    func updateOverlayColor(_ color: Color) {
        guard let hostingView = window?.contentView as? NSHostingView<OverlayView> else { return }
        var root = hostingView.rootView
        root.overlayColor = color
        hostingView.rootView = root
    }
    
    func updateOverlayTransparency(_ transparency: Double) {
        guard let hostingView = window?.contentView as? NSHostingView<OverlayView> else { return }
        var root = hostingView.rootView
        root.transparency = transparency
        hostingView.rootView = root
    }
    
    func updateWindowSize() {
        guard let window = window else { return }
        let contentRect = NSRect(
            x: SettingsManager.shared.windowPositionX,
            y: SettingsManager.shared.windowPositionY,
            width: SettingsManager.shared.windowWidth,
            height: SettingsManager.shared.windowHeight
        )
        window.setFrame(contentRect, display: true)
        window.setContentSize(NSSize(width: SettingsManager.shared.windowWidth, height: SettingsManager.shared.windowHeight))
        
        // 更新hosting view的尺寸
        if let hostingView = window.contentView as? NSHostingView<OverlayView> {
            hostingView.setFrameSize(NSSize(width: SettingsManager.shared.windowWidth, height: SettingsManager.shared.windowHeight))
        }
    }
}