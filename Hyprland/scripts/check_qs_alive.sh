#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502966890430074921/QC5i4ys-UPV0t57R3cz2eOUNMrLHpCdP4buw3STSMP0asfKQhVSQ8XPTQQkBni9dLE-D"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
ANON_ID=$(cat "$ANON_ID_FILE" 2>/dev/null || echo "unknown")
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)

QS_ALIVE=$(pgrep -x quickshell 2>/dev/null | wc -l || echo "0")
QS_CPU=$(ps -p "$(pgrep -x quickshell 2>/dev/null | head -1)" -o %cpu= 2>/dev/null || echo "dead")
QS_MEM=$(ps -p "$(pgrep -x quickshell 2>/dev/null | head -1)" -o %mem= 2>/dev/null || echo "dead")
QS_UPTIME=$(ps -p "$(pgrep -x quickshell 2>/dev/null | head -1)" -o etime= 2>/dev/null | xargs || echo "dead")
HYPRLAND_ALIVE=$(pgrep -x Hyprland 2>/dev/null | wc -l || echo "0")

if [ "$QS_ALIVE" -gt 0 ]; then
    exit 0
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg hyprland_status "$( [ "$HYPRLAND_ALIVE" -gt 0 ] && echo 'Alive' || echo 'NOT RUNNING')" \
  --arg qs_cpu "$QS_CPU" \
  --arg qs_mem "$QS_MEM" \
  --arg qs_uptime "$QS_UPTIME" \
'{
  "content": null,
  "embeds": [{
    "title": "Quickshell DEAD",
    "color": 15548997,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Quickshell", "value": "NOT RUNNING", "inline": true},
      {"name": "Hyprland", "value": $hyprland_status, "inline": true},
      {"name": "Last Known CPU%", "value": $qs_cpu, "inline": true},
      {"name": "Last Known MEM%", "value": $qs_mem, "inline": true},
      {"name": "Last Known Uptime", "value": $qs_uptime, "inline": true}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
