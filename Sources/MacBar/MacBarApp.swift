import SwiftUI

@main
struct MacBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("遮罩工具") {
            Color.clear.frame(width: 0, height: 0)
                .onAppear {
                    // 隐藏主窗口，但保持应用程序运行
                    if let window = NSApplication.shared.windows.first {
                        window.close()
                    }
                }
        }
        
        Settings {
            SettingsView()
        }
    }
}

class PreferencesWindowController: NSWindowController {
    static var shared: PreferencesWindowController?
    
    convenience init() {
        let settingsView = SettingsView()
            .frame(minWidth: 300, idealWidth: 300, maxWidth: 350, minHeight: 200, idealHeight: 250, maxHeight: 300)
        
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 250),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "遮罩工具设置"
        window.center()
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false  // Keep window in memory
        
        self.init(window: window)
        PreferencesWindowController.shared = self
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindowController: OverlayWindowController?
    var preferencesWindowController: PreferencesWindowController?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 确保应用有正常的激活策略，允许显示窗口
        NSApplication.shared.setActivationPolicy(.regular)
        print("[MacBar] Application did finish launching, activation policy set to .regular")

        // 创建状态栏图标
        setupStatusBar()
        
        // 创建并显示遮罩窗口
        DispatchQueue.main.async {
            self.showOverlayWindow()
            NSApplication.shared.activate(ignoringOtherApps: true)
            print("[MacBar] Overlay window requested to show")
            
            // 首次启动时显示设置窗口
            if UserDefaults.standard.bool(forKey: "FirstLaunch") == false {
                self.showPreferences()
                UserDefaults.standard.set(true, forKey: "FirstLaunch")
            }
        }
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.fill", accessibilityDescription: "遮罩工具")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
    }
    
    @objc func statusBarButtonClicked(_ sender: Any) {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "显示遮罩", action: #selector(showOverlayWindow), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "设置", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
    }
    
    @objc func showOverlayWindow() {
        if overlayWindowController == nil {
            overlayWindowController = OverlayWindowController()
        }
        overlayWindowController?.showWindow(nil)
        if let w = overlayWindowController?.window {
            // 强制置顶显示，覆盖全屏视频
            w.level = .screenSaver
            w.makeKeyAndOrderFront(nil)
            w.orderFrontRegardless()
        }
        if let w = overlayWindowController?.window {
            print("[MacBar] Overlay window frame: \(w.frame)")
        }
    }
    
    @objc func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 点击Dock图标时显示设置窗口
        if !flag {
            showPreferences()
        } else {
            // 如果有可见窗口，将设置窗口置于前台
            preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}