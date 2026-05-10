#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502966985665806396/n5ivqbH9GJGtHKxeiOf3U22fTymxtfwHfAmsAHuK9P2tPf4oFyqnMcW2n00Yli7qH_9y"

ERROR_LOG="$1"
ANON_ID=$(uuidgen 2>/dev/null || tr -dc 'a-f0-9' < /dev/urandom | head -c 16)
HOSTNAME=$(uname -n)
KERNEL=$(uname -r)
GPU=$(lspci 2>/dev/null | grep -i "vga\|3d" | head -1 | sed 's/.*: //')
CPU=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | sed 's/.*: //')
RAM=$(free -h 2>/dev/null | grep "^Mem:" | awk '{print $2}')
FAILURE_OUTPUT=$(cat "$ERROR_LOG" 2>/dev/null | tail -30 || echo "no log")

PAYLOAD=$(jq -n \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg kernel "$KERNEL" \
  --arg gpu "$GPU" \
  --arg cpu "$CPU" \
  --arg ram "$RAM" \
  --arg failure_output "${FAILURE_OUTPUT:0:1500}" \
'{
  "content": null,
  "embeds": [{
    "title": "Install Failure",
    "color": 15548997,
    "fields": [
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Kernel", "value": $kernel, "inline": true},
      {"name": "GPU", "value": $gpu, "inline": true},
      {"name": "CPU", "value": $cpu, "inline": true},
      {"name": "RAM", "value": $ram, "inline": true},
      {"name": "Failure Output", "value": ("```" + $failure_output + "```"), "inline": false}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
