import SwiftUI
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var overlayColor: Color = .black
    @Published var transparency: Double = 1.0
    @Published var windowPositionX: Double = 100
    @Published var windowPositionY: Double = 100
    @Published var windowWidth: Double = 300
    @Published var windowHeight: Double = 70
    
    private let userDefaults = UserDefaults.standard
    private let colorKey = "OverlayColor"
    private let transparencyKey = "Transparency"
    private let positionXKey = "WindowPositionX"
    private let positionYKey = "WindowPositionY"
    private let widthKey = "WindowWidth"
    private let heightKey = "WindowHeight"
    
    private init() {
        // 注册默认值，避免首次运行从UserDefaults读取到0而覆盖默认设置
        userDefaults.register(defaults: [
            transparencyKey: 1.0,
            positionXKey: 100,
            positionYKey: 100,
            widthKey: 300,
            heightKey: 70,
            colorKey + "R": 0.0,
            colorKey + "G": 0.0,
            colorKey + "B": 0.0
        ])
        loadSettings()
    }
    
    func saveSettings() {
        // Save color as RGB values
        let rgb = overlayColor.toRGB()
        userDefaults.set(rgb.r, forKey: colorKey + "R")
        userDefaults.set(rgb.g, forKey: colorKey + "G")
        userDefaults.set(rgb.b, forKey: colorKey + "B")
        
        userDefaults.set(transparency, forKey: transparencyKey)
        userDefaults.set(windowPositionX, forKey: positionXKey)
        userDefaults.set(windowPositionY, forKey: positionYKey)
        userDefaults.set(windowWidth, forKey: widthKey)
        userDefaults.set(windowHeight, forKey: heightKey)
    }
    
    func loadSettings() {
        // 仅当键存在时才覆盖默认值，避免首次运行为0导致不可见
        if userDefaults.object(forKey: colorKey + "R") != nil,
           userDefaults.object(forKey: colorKey + "G") != nil,
           userDefaults.object(forKey: colorKey + "B") != nil {
            let r = userDefaults.double(forKey: colorKey + "R")
            let g = userDefaults.double(forKey: colorKey + "G")
            let b = userDefaults.double(forKey: colorKey + "B")
            overlayColor = Color(red: r, green: g, blue: b)
        }

        if userDefaults.object(forKey: transparencyKey) != nil {
            transparency = userDefaults.double(forKey: transparencyKey)
        }
        if userDefaults.object(forKey: positionXKey) != nil {
            windowPositionX = userDefaults.double(forKey: positionXKey)
        }
        if userDefaults.object(forKey: positionYKey) != nil {
            windowPositionY = userDefaults.double(forKey: positionYKey)
        }
        if userDefaults.object(forKey: widthKey) != nil {
            let w = userDefaults.double(forKey: widthKey)
            windowWidth = max(w, 200) // 保证最小宽度
        }
        if userDefaults.object(forKey: heightKey) != nil {
            let h = userDefaults.double(forKey: heightKey)
            windowHeight = max(h, 70) // 保证最小高度
        }
    }
    
    /// Persist the latest window dimensions so the overlay can restore them on launch.
    func persistWindowSize(width: Double, height: Double) {
        let clampedWidth = max(width, 200)
        let clampedHeight = max(height, 70)
        
        if windowWidth != clampedWidth || windowHeight != clampedHeight {
            windowWidth = clampedWidth
            windowHeight = clampedHeight
        }
        saveSettings()
    }
    
    /// Persist the latest window origin to keep the overlay anchored where the user left it.
    func persistWindowPosition(x: Double, y: Double) {
        if windowPositionX != x || windowPositionY != y {
            windowPositionX = x
            windowPositionY = y
        }
        saveSettings()
    }
}

// Extension to convert Color to RGB
extension Color {
    func toRGB() -> (r: Double, g: Double, b: Double) {
        // Extracting RGB values from Color
        let cgColor = NSColor(self).cgColor
        
        guard let components = cgColor.components, components.count >= 3 else {
            return (0.0, 0.0, 0.0)
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return (r, g, b)
    }
}
