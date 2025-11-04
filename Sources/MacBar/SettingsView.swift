import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        Form {
            Section("遮罩外观") {
                ColorPicker("遮罩颜色", selection: $settings.overlayColor, supportsOpacity: false)
                    .onChange(of: settings.overlayColor) { newColor in
                        settings.saveSettings()
                        OverlayWindowController.shared?.updateOverlayColor(newColor)
                    }
                
                HStack(spacing: 12) {
                    Text("透明度")
                    Slider(value: $settings.transparency, in: 0...1) { editing in
                        if !editing {
                            settings.saveSettings()
                            OverlayWindowController.shared?.updateOverlayTransparency(settings.transparency)
                        }
                    }
                    .controlSize(.small)
                    Text("\(Int(settings.transparency * 100))%")
                        .foregroundColor(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }
                .onChange(of: settings.transparency) { _ in
                    OverlayWindowController.shared?.updateOverlayTransparency(settings.transparency)
                }
            }
            
            Section("窗口尺寸") {
                Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        Text("宽度")
                        sizeControls(
                            value: $settings.windowWidth,
                            range: 200...2000,
                            step: 10,
                            onCommit: applyWidthChange
                        )
                        Text("\(Int(settings.windowWidth)) px")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                    }
                    
                    GridRow {
                        Text("高度")
                        sizeControls(
                            value: $settings.windowHeight,
                            range: 70...1200,
                            step: 10,
                            onCommit: applyHeightChange
                        )
                        Text("\(Int(settings.windowHeight)) px")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                    }
                }
                .gridColumnAlignment(.leading)
                
                Button("重置尺寸为默认值") {
                    resetWindowSize()
                }
                .buttonStyle(.link)
                .controlSize(.small)
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 12)
        .frame(minWidth: 320, idealWidth: 340, minHeight: 260)
        .onAppear {
            // Make sure settings are loaded
            settings.loadSettings()
        }
    }
    
    @ViewBuilder
    private func sizeControls(value: Binding<Double>, range: ClosedRange<Double>, step: Double, onCommit: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 8) {
            TextField("", value: value, formatter: Self.integerFormatter)
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onCommit(value.wrappedValue)
                }
            
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .controlSize(.small)
        }
        .onChange(of: value.wrappedValue) { newValue in
            onCommit(newValue)
        }
    }
    
    private func applyWidthChange(_ newValue: Double) {
        let clamped = min(max(newValue, 200), 2000)
        if clamped != newValue {
            settings.windowWidth = clamped
            return
        }
        settings.persistWindowSize(width: clamped, height: settings.windowHeight)
        OverlayWindowController.shared?.updateWindowSize()
    }
    
    private func applyHeightChange(_ newValue: Double) {
        let clamped = min(max(newValue, 70), 1200)
        if clamped != newValue {
            settings.windowHeight = clamped
            return
        }
        settings.persistWindowSize(width: settings.windowWidth, height: clamped)
        OverlayWindowController.shared?.updateWindowSize()
    }
    
    private func resetWindowSize() {
        // 回到便于操作的默认尺寸
        let defaultSize = CGSize(width: 600, height: 250)
        settings.windowWidth = defaultSize.width
        settings.windowHeight = defaultSize.height
        settings.persistWindowSize(width: defaultSize.width, height: defaultSize.height)
        OverlayWindowController.shared?.updateWindowSize()
    }
}

#Preview {
    SettingsView()
        .frame(width: 340, height: 280)
}
