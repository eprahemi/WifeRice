
# Eprahemi

> **"My personal Arch Linux Hyprland setup — optimized, themed, and built for sharing."**

A complete, high-end Arch Linux desktop environment featuring Hyprland compositor, QuickShell widgets, dynamic Matugen theming, and carefully crafted configurations for a modern Linux experience.

---

## ⚡ One-Line Automated Installer (Recommended)

For the easiest, permission-error-free installation, run this single command in your terminal. This method requires no manual cloning, automatically handles `sudo` for system directories, and sets up everything in one step:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/WifeRice/main/install.sh)"
```

**What this installer handles automatically:**
- Downloads the latest dotfiles directly from the repository
- Uses `sudo` for system-level writes (fixes `/usr/share/wallpapers` and SDDM permission errors)
- Creates timestamped backups of existing `~/.config` files before overwriting
- Restores all configs: Hyprland, Kitty, Neovim, Rofi, SwayNC, Matugen
- Installs lockscreen and SDDM login wallpapers to system directories
- Reloads Hyprland automatically if the compositor is running
- Writes version info for automatic update notifications

> **Perfect for friends:** This command avoids all manual permission fixes and is the simplest way to replicate my exact Hyprland setup.

---

## 🔄 Built-in Update System

This config includes an automatic update notification system:

- **Background notifier:** Checks for updates every 10 minutes
- **Update button:** Appears in your topbar when a new version is available
- **One-click update:** Hold the update button in the popup to install
- **Changelog display:** See what's new before updating

Updates are pulled directly from this repository (`eprahemi/WifeRice`), so when I push improvements, you'll be notified automatically.

---

## 📂 Repository Structure

The repository is organized by component, each mapping directly to its install target:

| Directory | Component | Install Path |
|-----------|-----------|--------------|
| `Hyprland/` | **Compositor** | `~/.config/hypr/` |
| `Kitty/` | **Terminal** | `~/.config/kitty/` |
| `Neovim/` | **Editor** | `~/.config/nvim/` |
| `Rofi/` | **Launcher** | `~/.config/rofi/` |
| `SwayNC/` | **Notifications** | `~/.config/swaync/` |
| `Matugen/` | **Theming** | `~/.config/matugen/` |
| `SDDM/` | **Login Manager** | `/usr/share/sddm/themes/` |
| `Wallpapers/` | **Lockscreen Image** | `/usr/share/wallpapers/` |
| `SDDM-Wallpaper/` | **Login Background** | `/usr/share/sddm/themes/matugen-minimal/` |

---

## 🚀 Manual Restore (If Already Cloned)

If you have already cloned this repository locally, you can use the included `restore.sh` script to deploy configs:

```bash
chmod +x restore.sh && ./restore.sh
```

**What this script does:**
1.  **Backups:** Safely moves your existing configs to a timestamped backup folder (`~/.config/backup_...`).
2.  **Restores:** Copies all config files to `~/.config/`.
3.  **Wallpapers:** Installs `lock.png` to `/usr/share/wallpapers/` and the SDDM wallpaper to `/usr/share/sddm/themes/matugen-minimal/` (requires `sudo`).
4.  **Reloads:** Automatically signals Hyprland to reload the configuration.

---

## 🖼 Wallpapers

### Included Wallpapers

| Wallpaper | Location | Purpose |
|-----------|----------|---------|
| `Wallpapers/lock.png` | `/usr/share/wallpapers/lock.png` | Hyprlock lockscreen background |
| `SDDM-Wallpaper/wallpaper.png` | `/usr/share/sddm/themes/matugen-minimal/wallpaper.png` | SDDM login screen background |

### How to Change Wallpapers

**Lockscreen:**
1.  Replace `/usr/share/wallpapers/lock.png` with your own image (keep the filename `lock.png`).
2.  Or update the path inside `~/.config/hypr/config/settings.conf` under the `[LOCK]` section.

**Login Screen (SDDM):**
1.  Replace `/usr/share/sddm/themes/matugen-minimal/wallpaper.png` with your own image.
2.  Or edit `/usr/share/sddm/themes/matugen-minimal/theme.conf` to point to a different file.

> 💡 **Tip:** The `Wallpapers/` and `SDDM-Wallpaper/` folders in this repo serve as your backup. When you pick a new wallpaper you like, copy it into these folders so you never lose your preferred setup.

---

## 🛠 Manual Installation

If you prefer manual control, copy the contents of each directory to its corresponding location:

```bash
# Core Hyprland
cp -r Hyprland/* ~/.config/hypr/

# Application Configs
cp Kitty/* ~/.config/kitty/
cp Neovim/* ~/.config/nvim/
cp Rofi/* ~/.config/rofi/
cp SwayNC/* ~/.config/swaync/

# Matugen Theme Engine
cp Matugen/config.toml ~/.config/matugen/
cp Matugen/templates/* ~/.config/matugen/templates/

# Wallpapers (requires sudo)
sudo cp Wallpapers/lock.png /usr/share/wallpapers/
sudo cp SDDM-Wallpaper/wallpaper.png /usr/share/sddm/themes/matugen-minimal/
```

After copying, restart Hyprland (`Super+Shift+Q` to log out and back in) or run `hyprctl reload`.

---

## ⚠️ Important Notes

*   **Weather API Key:** For security reasons, the `~/.config/hypr/scripts/quickshell/calendar/.env` file containing the OpenWeather API key is **excluded** from this repository. You must manually create this file and insert your own API key for the weather widget to function.
*   **Dynamic Theming:** The `Matugen/templates/` directory contains templates that are processed by the `matugen` tool to inject live colors into your apps whenever your wallpaper changes.
*   **Update Source:** The built-in update system pulls from **`eprahemi/WifeRice`** — when I push updates, you'll get notified automatically through the topbar widget.

---

## 📦 Prerequisites for Fresh Install

```bash
# Core
sudo pacman -S hyprland kitty rofi-wayland neovim

# QuickShell and theming
yay -S quickshell matugen-git

# Media and audio
sudo pacman -S playerctl cava pipewire pipewire-pulse pavucontrol

# Notifications and OSD
sudo pacman -S swaync swayosd

# Network and bluetooth
sudo pacman -S networkmanager bluez

# Wallpaper
yay -S awww-git   # or mpvpaper

# Screenshot
sudo pacman -S grim slurp

# Other utilities
sudo pacman -S thunar lxappearance qt5ct qt6ct
```

---

## 🙏 Credits

This configuration was originally inspired by the work of **[ilyamiro](https://github.com/ilyamiro)** and their **[imperative-dots](https://github.com/ilyamiro/imperative-dots)** project. Their attention to detail and integration of the Matugen theming engine provided the initial foundation.

This repository represents my evolved version — tailored to my workflow, with custom theming, optimizations, and my own update infrastructure built on top of that solid foundation.

---

*Built with ❤️ by [Eprahemi](https://github.com/eprahemi) — based on the work of [ilyamiro](https://github.com/ilyamiro).*

*Repository: [eprahemi/WifeRice](https://github.com/eprahemi/WifeRice)*
