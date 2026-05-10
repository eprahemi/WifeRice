# QuickShell UI Components

> **Install path:** `~/.config/hypr/scripts/quickshell/`

QtQuick/QML-based UI widgets rendered by QuickShell on Wayland.

## Core Files

| File | Purpose |
|------|---------|
| `Main.qml` | Entry point, spawns all widget processes |
| `TopBar.qml` | Top status bar (workspaces, system tray, clock) |
| `Floating.qml` | Floating widget container |
| `Lock.qml` | Lock screen interface |
| `Config.qml` | Configuration panel |
| `Scaler.qml` | Responsive scaling helper |
| `ScreenshotOverlay.qml` | Screenshot annotation overlay |
| `MatugenColors.qml` | Color provider for matugen palette |
| `SysData.qml` | System data provider component |
| `WindowRegistry.js` | Window state management |
| `qs_colors.json` | Color definitions for QuickShell |
| `workspaces.sh` | Workspace indicator script |

## Widget Modules

| Module | Purpose |
|--------|---------|
| `applauncher/` | Application launcher (Rofi alternative) |
| `battery/` | Battery status popup |
| `calendar/` | Calendar with weather widget |
| `clipboard/` | Clipboard history manager |
| `focustime/` | Pomodoro timer and focus tracking |
| `guide/` | Interactive dotfiles guide (Super+H) |
| `monitors/` | Display management popup |
| `movies/` | Video widget |
| `music/` | Music player with lyrics and equalizer |
| `network/` | Wi-Fi, Bluetooth, and Ethernet panel |
| `notifications/` | Notification popup display |
| `quickactions/` | Quick action tiles (timer, draw, usage) |
| `settings/` | System settings panel |
| `stewart/` | Voice assistant (reserved) |
| `updater/` | Dotfiles update checker |
| `volume/` | Volume mixer popup |
| `wallpaper/` | Wallpaper picker with Matugen integration |
| `watchers/` | Background polling scripts for system state |
