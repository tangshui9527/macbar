import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 15) {
                HStack {
                    Text("遮罩颜色")
                        .font(.headline)
                    Spacer()
                    ColorPicker("", selection: $settings.overlayColor)
                        .onChange(of: settings.overlayColor) { newColor in
                            settings.saveSettings()
                            OverlayWindowController.shared?.updateOverlayColor(newColor)
                        }
                        .labelsHidden()
                        .frame(width: 44, height: 44)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("透明度")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(settings.transparency * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.transparency, in: 0...1) { changed in
                        if !changed {
                            settings.saveSettings()
                            OverlayWindowController.shared?.updateOverlayTransparency(settings.transparency)
                        }
                    }
                    .onChange(of: settings.transparency) { _ in
                        // Update transparency immediately as user drags
                        OverlayWindowController.shared?.updateOverlayTransparency(settings.transparency)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            // 新增窗口尺寸调节区域
            VStack(spacing: 15) {
                HStack {
                    Text("窗口尺寸")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("宽度")
                        Spacer()
                        Text("\(Int(settings.windowWidth)) px")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.windowWidth, in: 200...2000, step: 10) { changed in
                        if !changed {
                            settings.saveSettings()
                            // 更新窗口尺寸
                            OverlayWindowController.shared?.updateWindowSize()
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("高度")
                        Spacer()
                        Text("\(Int(settings.windowHeight)) px")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.windowHeight, in: 50...90, step: 5) { changed in
                        if !changed {
                            settings.saveSettings()
                            // 更新窗口尺寸
                            OverlayWindowController.shared?.updateWindowSize()
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 280, maxWidth: 320, minHeight: 180)
        .onAppear {
            // Make sure settings are loaded
            settings.loadSettings()
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 300, height: 200)
}