#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502918449968582807/AUcvD9Wtv3rzfzLtHFwbkB6musjdHzbP_389Z0oKguK69Nprakzl_IHYaQ61S3lJvLtR"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
if [ -f "$ANON_ID_FILE" ]; then
    ANON_ID=$(cat "$ANON_ID_FILE")
else
    ANON_ID=$(uuidgen 2>/dev/null || tr -dc 'a-f0-9' < /dev/urandom | head -c 16)
    echo "$ANON_ID" > "$ANON_ID_FILE"
fi

DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
KERNEL=$(uname -r)
HOSTNAME=$(uname -n)
GPU=$(lspci 2>/dev/null | grep -i "vga\|3d" | head -1 | sed 's/.*: //')

HYPRLAND_ERRORS=$(journalctl --user -u hyprland -n 50 --no-pager -p err 2>/dev/null | tail -20 || echo "none")
QUICKSHELL_ERRORS=$(journalctl --user -u quickshell -n 50 --no-pager -p err 2>/dev/null | tail -20 || echo "none")
SERVICE_FAILURES=$(systemctl --user --failed --no-pager 2>/dev/null | tail -10 || echo "none")
OOM_EVENTS=$(journalctl -n 30 --no-pager 2>/dev/null | grep -i "oom\|out of memory" | tail -5 || echo "none")
DMESG_ERRORS=$(dmesg 2>/dev/null | grep -i "error\|fail\|critical" | tail -10 || echo "none")

HYPRLAND_CRASHES=$(journalctl --user -u hyprland -n 100 --no-pager 2>/dev/null | grep -i "segfault\|panic\|abort\|crash" | tail -5 || echo "none")
QUICKSHELL_CRASHES=$(journalctl --user -u quickshell -n 100 --no-pager 2>/dev/null | grep -i "segfault\|panic\|abort\|crash" | tail -5 || echo "none")

if [ "$HYPRLAND_ERRORS" = "none" ] && [ "$QUICKSHELL_ERRORS" = "none" ] && \
   [ "$SERVICE_FAILURES" = "none" ] && [ "$OOM_EVENTS" = "none" ] && \
   [ "$DMESG_ERRORS" = "none" ] && [ "$HYPRLAND_CRASHES" = "none" ] && \
   [ "$QUICKSHELL_CRASHES" = "none" ]; then
    exit 0
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg kernel "$KERNEL" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg gpu "$GPU" \
  --arg hyprland_errors "${HYPRLAND_ERRORS:0:500}" \
  --arg quickshell_errors "${QUICKSHELL_ERRORS:0:500}" \
  --arg service_failures "${SERVICE_FAILURES:0:500}" \
  --arg oom_events "${OOM_EVENTS:0:500}" \
  --arg dmesg_errors "${DMESG_ERRORS:0:500}" \
  --arg hyprland_crashes "${HYPRLAND_CRASHES:0:500}" \
  --arg quickshell_crashes "${QUICKSHELL_CRASHES:0:500}" \
'{
  "content": null,
  "embeds": [{
    "title": "Problem Report",
    "color": 15548997,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Kernel", "value": $kernel, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "GPU", "value": $gpu, "inline": true},
      {"name": "Hyprland Errors", "value": ("```" + $hyprland_errors + "```"), "inline": false},
      {"name": "Quickshell Errors", "value": ("```" + $quickshell_errors + "```"), "inline": false},
      {"name": "Service Failures", "value": ("```" + $service_failures + "```"), "inline": false},
      {"name": "OOM Events", "value": ("```" + $oom_events + "```"), "inline": false},
      {"name": "dmesg Errors", "value": ("```" + $dmesg_errors + "```"), "inline": false},
      {"name": "Hyprland Crashes", "value": ("```" + $hyprland_crashes + "```"), "inline": false},
      {"name": "Quickshell Crashes", "value": ("```" + $quickshell_crashes + "```"), "inline": false}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
