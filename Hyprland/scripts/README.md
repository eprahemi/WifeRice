# Hyprland Scripts

> **Install path:** `~/.config/hypr/scripts/`

Shell scripts for system management and QuickShell IPC communication.

## Root Scripts

| File | Purpose |
|------|---------|
| `exit.sh` | Session exit/lock/reboot/power menu |
| `focus_next_monitor.sh` | Cycle focus between monitors |
| `init.sh` | Initial setup script (first boot) |
| `lock.sh` | Screen lock with Hyprlock |
| `qs_manager.sh` | **Main IPC router** toggles all QuickShell widgets |
| `reload.sh` | Reloads Hyprland configuration |
| `screenshot.sh` | Screenshot capture with Grim/Slurp |
| `settings_watcher.sh` | Watches settings.json, regenerates configs |
| `update_notifier.sh` | Checks for dotfiles updates from GitHub |
| `volume_listener.sh` | Daemon for volume change events |

## Subdirectories

| Directory | Contents |
|-----------|----------|
| `quickshell/` | QuickShell QML widgets and backend scripts |
| `templates/` | Matugen templates (parent directory) |
