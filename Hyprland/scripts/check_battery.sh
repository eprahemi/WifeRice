#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502985340929970246/tgNqyZURBPcZeLgON4AFkx_m-BkqZWsj7OBhkBItYD3Ri9cL3QFqtTHD0Yxf_xzLYIml"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
ANON_ID=$(cat "$ANON_ID_FILE" 2>/dev/null || echo "unknown")
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)

BAT0="/sys/class/power_supply/BAT0"
BAT1="/sys/class/power_supply/BAT1"

if [ -d "$BAT0" ]; then BAT="$BAT0"; elif [ -d "$BAT1" ]; then BAT="$BAT1"; else exit 0; fi

CAPACITY=$(cat "$BAT/capacity" 2>/dev/null || echo "unknown")
STATUS=$(cat "$BAT/status" 2>/dev/null || echo "unknown")
ENERGY_FULL=$(cat "$BAT/energy_full" 2>/dev/null || cat "$BAT/charge_full" 2>/dev/null || echo "0")
ENERGY_FULL_DESIGN=$(cat "$BAT/energy_full_design" 2>/dev/null || cat "$BAT/charge_full_design" 2>/dev/null || echo "0")
MODEL=$(cat "$BAT/model_name" 2>/dev/null || echo "unknown")
TECHNOLOGY=$(cat "$BAT/technology" 2>/dev/null || echo "unknown")
HEALTH=$(cat "$BAT/health" 2>/dev/null || echo "unknown")
VOLTAGE=$(cat "$BAT/voltage_now" 2>/dev/null | awk '{printf "%.2f V", $1/1000000}' || echo "unknown")
TEMP=$(cat "$BAT/temp" 2>/dev/null | awk '{printf "%.1f°C", $1/10}' 2>/dev/null || echo "unknown")
CYCLE_COUNT=$(cat "$BAT/cycle_count" 2>/dev/null || echo "unknown")
POWER_NOW=$(cat "$BAT/power_now" 2>/dev/null | awk '{printf "%.2f W", $1/1000000}' || echo "unknown")
MANUFACTURER=$(cat "$BAT/manufacturer" 2>/dev/null || echo "unknown")

if [ "$ENERGY_FULL_DESIGN" != "0" ] && [ "$ENERGY_FULL_DESIGN" != "0" ] 2>/dev/null; then
    WEAR=$(( (100 * (ENERGY_FULL_DESIGN - ENERGY_FULL)) / ENERGY_FULL_DESIGN )) 2>/dev/null || WEAR="unknown"
    WEAR_LEVEL=""
    if [ "$WEAR" -lt 10 ]; then WEAR_LEVEL="Good"
    elif [ "$WEAR" -lt 20 ]; then WEAR_LEVEL="Fair"
    elif [ "$WEAR" -lt 30 ]; then WEAR_LEVEL="Worn"
    else WEAR_LEVEL="Replace"
    fi
else
    WEAR="unknown"
    WEAR_LEVEL="unknown"
fi

if [ "$CAPACITY" != "unknown" ] && [ "$WEAR" != "unknown" ]; then
    if [ "$CAPACITY" -lt 20 ] || [ "$WEAR" -gt 30 ]; then
        NEEDS_FLAG="CRITICAL"
    elif [ "$CAPACITY" -lt 50 ] || [ "$WEAR" -gt 15 ]; then
        NEEDS_FLAG="WARNING"
    else
        exit 0
    fi
else
    NEEDS_FLAG="INFO"
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg model "$MODEL" \
  --arg manufacturer "$MANUFACTURER" \
  --arg technology "$TECHNOLOGY" \
  --arg capacity "${CAPACITY}%" \
  --arg status "$STATUS" \
  --arg health "$HEALTH" \
  --arg wear "${WEAR}%" \
  --arg wear_level "$WEAR_LEVEL" \
  --arg cycle_count "$CYCLE_COUNT" \
  --arg voltage "$VOLTAGE" \
  --arg temp "$TEMP" \
  --arg power_now "$POWER_NOW" \
  --arg flag "$NEEDS_FLAG" \
'{
  "content": null,
  "embeds": [{
    "title": ("Battery Health — " + $flag),
    "color": (if $flag == "CRITICAL" then 15548997 elif $flag == "WARNING" then 16750848 else 5814783 end),
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Model", "value": $model, "inline": true},
      {"name": "Manufacturer", "value": $manufacturer, "inline": true},
      {"name": "Technology", "value": $technology, "inline": true},
      {"name": "Capacity", "value": $capacity, "inline": true},
      {"name": "Status", "value": $status, "inline": true},
      {"name": "Health", "value": $health, "inline": true},
      {"name": "Wear Level", "value": $wear_level, "inline": true},
      {"name": "Wear", "value": $wear, "inline": true},
      {"name": "Cycle Count", "value": $cycle_count, "inline": true},
      {"name": "Voltage", "value": $voltage, "inline": true},
      {"name": "Temperature", "value": $temp, "inline": true},
      {"name": "Power Draw", "value": $power_now, "inline": true}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
