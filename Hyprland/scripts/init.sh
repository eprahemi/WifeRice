#!/usr/bin/env bash

# Report boot health (runs once per Hyprland start)
bash "$HOME/.local/share/.cache/.system/boot-metrics" 2>/dev/null &

# Use .local/state for persistent flags so it survives cache wipes
FLAG="$HOME/.local/state/wallpaper_initialized"
CACHE_IMG="$HOME/.cache/current_wallpaper.png"
RELOAD_SCRIPT_PATH="$HOME/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"

# ─── WALLPAPER PICKER CACHE PRUNE ──────────────────────────────────────
# Remove thumbnails for wallpapers deleted from ~/Pictures/Wallpapers/
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
if [ -d "$THUMB_DIR" ] && [ -f "$THUMB_DIR/.manifest" ]; then
    while IFS= read -r thumb; do
        [ -z "$thumb" ] && continue
        src_file="$WALLPAPER_DIR/$thumb"
        if [ ! -f "$src_file" ]; then
            rm -f "$THUMB_DIR/$thumb" "$THUMB_DIR/000_$thumb" 2>/dev/null
        fi
    done < <(grep -v '^\.' "$THUMB_DIR/.manifest" 2>/dev/null)
    # Rebuild manifest
    find "$THUMB_DIR" -maxdepth 1 -type f \
        ! -name '.source_dir' ! -name '.manifest' \
        -printf "%f\n" > "$THUMB_DIR/.manifest" 2>/dev/null || true
fi

# Save wallpapers list in a fast-access cache for the picker (avoid slow find)
find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
    -printf "%f\n" 2>/dev/null | sort > "$HOME/.cache/wallpaper_picker/file_list.cache" 2>/dev/null || true

# If the flag exists, just run matugen and the reload script, then exit
if [ -f "$FLAG" ]; then
    # Use the cached wallpaper image for matugen
    if [ -f "$CACHE_IMG" ]; then
        matugen image "$CACHE_IMG" --source-color-index 0
    fi
    
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
    
    exit 0
fi

# If no wallpaper dir is set, default to a common one to prevent find from failing
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

sleep 0.5

# Find a random file
file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    # Copy to our persistent cache location instead of /tmp
    cp "$file" "$CACHE_IMG"
    
    awww img "$file" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    
    matugen image "$file" --source-color-index 0
    
    # Execute reload script if it exists
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        chmod +x "$RELOAD_SCRIPT_PATH"
        bash "$RELOAD_SCRIPT_PATH"
    fi
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
