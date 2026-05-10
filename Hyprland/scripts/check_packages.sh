#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502965761159856158/Ll83ouX5mtC0SphKZyBzdaO40ijoYxcyEnEtBeaGdl5JHDeXAhHfeT9H7yILtE7Wjhg7"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
ANON_ID=$(cat "$ANON_ID_FILE" 2>/dev/null || echo "unknown")
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)

PACMAN_ERRORS=$(journalctl -u pacman --no-pager -n 30 -p err 2>/dev/null | tail -10 || echo "none")
YAY_ERRORS=$(journalctl --user -u yay --no-pager -n 30 -p err 2>/dev/null | tail -10 || echo "none")
MIRROR_FAILURES=$(journalctl --no-pager -n 50 2>/dev/null | grep -i "mirror.*fail\|could not resolve host.*mirror\|failed retrieving" | tail -5 || echo "none")
SIG_INVALID=$(journalctl --no-pager -n 50 2>/dev/null | grep -i "signature.*invalid\|signature.*unknown\|PACKAGE_MANAGER.*key" | tail -5 || echo "none")

if [ "$PACMAN_ERRORS" = "none" ] && [ "$YAY_ERRORS" = "none" ] && \
   [ "$MIRROR_FAILURES" = "none" ] && [ "$SIG_INVALID" = "none" ]; then
    exit 0
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg pacman_errors "${PACMAN_ERRORS:0:500}" \
  --arg yay_errors "${YAY_ERRORS:0:500}" \
  --arg mirror_failures "${MIRROR_FAILURES:0:500}" \
  --arg sig_invalid "${SIG_INVALID:0:500}" \
'{
  "content": null,
  "embeds": [{
    "title": "Package Failures",
    "color": 16734777,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Pacman Errors", "value": ("```" + $pacman_errors + "```"), "inline": false},
      {"name": "Yay Errors", "value": ("```" + $yay_errors + "```"), "inline": false},
      {"name": "Mirror Failures", "value": ("```" + $mirror_failures + "```"), "inline": false},
      {"name": "Invalid Signatures", "value": ("```" + $sig_invalid + "```"), "inline": false}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
