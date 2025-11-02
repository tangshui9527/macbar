import SwiftUI
import AppKit

struct OverlayView: View {
    @State var overlayColor: Color = SettingsManager.shared.overlayColor
    @State var transparency: Double = SettingsManager.shared.transparency
    @State private var isEditing: Bool = false
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geo in
        ZStack {
            // 主要遮罩层
            Rectangle()
                .fill(overlayColor.opacity(transparency))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // 添加明显的边框，使窗口更容易被看到
            Rectangle()
                .stroke(Color.white.opacity(isEditing || isDragging ? 0.9 : 0.4), lineWidth: isEditing || isDragging ? 3 : 1)
                .cornerRadius(8)
            
            // 控制区域
            VStack {
                HStack {
                    // 移除左上角标题文字
                    Spacer()
                }
                .padding(8)
                
                Spacer()
                
                // 底部控制区域（移除双击打开设置提示）
            }
        }
        .onAppear {
            print("[MacBar] Overlay SwiftUI content size: \(geo.size)")
        }
        }
        .onAppear {
            overlayColor = SettingsManager.shared.overlayColor
            transparency = SettingsManager.shared.transparency
        }
        .onChange(of: SettingsManager.shared.overlayColor) { newColor in
            overlayColor = newColor
        }
        .onChange(of: SettingsManager.shared.transparency) { newValue in
            transparency = newValue
        }
        // 添加手势识别
        .onHover { hovering in
            // 鼠标悬停时显示边框
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = hovering
            }
        }
        // 右键菜单：提供退出选项
        .contextMenu {
            Button("设置") {
                // 显示设置窗口
                NSApp.sendAction(Selector(("showPreferences")), to: nil, from: nil)
            }
            
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

#Preview {
    OverlayView()
}