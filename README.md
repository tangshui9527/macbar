# MacBar

MacBar is a lightweight macOS overlay bar built with SwiftUI and AppKit.

It creates a borderless floating mask window that stays above normal windows and can appear over full-screen apps. The main use case is covering part of the screen during screen sharing, recording, demos, or daily work when you want a simple movable visual blocker.

## Features

- Floating overlay window with a clean borderless look
- Stays visible across Spaces and over full-screen apps
- Drag to move the overlay
- Resize from window edges and corners
- Adjustable color and opacity
- Persistent position and size between launches
- Simple settings window for appearance and dimensions
- Right-click menu with Settings and Quit

## Project Structure

- [`Package.swift`](/Users/tangshui/Documents/macbar/Package.swift): Swift Package definition
- [`Sources/MacBar/MacBarApp.swift`](/Users/tangshui/Documents/macbar/Sources/MacBar/MacBarApp.swift): app entry point and window lifecycle
- [`Sources/MacBar/OverlayWindowController.swift`](/Users/tangshui/Documents/macbar/Sources/MacBar/OverlayWindowController.swift): floating window behavior, dragging, resizing, persistence hooks
- [`Sources/MacBar/OverlayView.swift`](/Users/tangshui/Documents/macbar/Sources/MacBar/OverlayView.swift): SwiftUI overlay content
- [`Sources/MacBar/SettingsView.swift`](/Users/tangshui/Documents/macbar/Sources/MacBar/SettingsView.swift): settings UI
- [`Sources/MacBar/SettingsManager.swift`](/Users/tangshui/Documents/macbar/Sources/MacBar/SettingsManager.swift): saved user preferences

## Requirements

- macOS 13 or later
- Xcode 15+ or a Swift 5.9 toolchain

## Build

Using Swift Package Manager:

```bash
swift build
```

Run directly from the package:

```bash
swift run MacBar
```

If you prefer Xcode, open the workspace or package and run the `MacBar` target.

## Usage

1. Launch the app.
2. A floating overlay bar appears on screen.
3. Drag inside the bar to move it.
4. Drag from the edges to resize it.
5. Open Settings on first launch or from the right-click menu.
6. Adjust color, opacity, width, and height.

The app remembers the last position, size, color, and transparency.

## Notes

- The app uses a floating window level and full-screen auxiliary behavior so it can stay visible above more contexts than a normal window.
- Current settings are stored with `UserDefaults`.
- The repository also contains a built app under [`dist/MacBar.app`](/Users/tangshui/Documents/macbar/dist/MacBar.app), but the source under [`Sources/MacBar`](/Users/tangshui/Documents/macbar/Sources/MacBar) is the authoritative code.

## Known Limitations

- There are currently no automated tests in the repository.
- The project is macOS-only.
- The UI text is currently mixed, with user-facing strings primarily in Chinese.

## License

No license file is included yet. All rights reserved by default unless a license is added.
