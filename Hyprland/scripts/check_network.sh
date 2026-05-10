#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1502985479371493488/0AQVOGhYOOvUqStEYTh02mcvJzDtSQj7Eb-9dRmyyZ0EDVQNcUc-87NypgZCpSKvgUax"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
ANON_ID=$(cat "$ANON_ID_FILE" 2>/dev/null || echo "unknown")
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)

# Interfaces
WIFI_IF=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1 || echo "")
ETH_IF=$(ip -o link show 2>/dev/null | awk -F': ' '/eth|enp/{print $2; exit}' || echo "")

# MAC addresses
WIFI_MAC=$(ip link show "$WIFI_IF" 2>/dev/null | grep "link/ether" | awk '{print $2}' || echo "none")
ETH_MAC=$(ip link show "$ETH_IF" 2>/dev/null | grep "link/ether" | awk '{print $2}' || echo "none")

# IP addresses
WIFI_IP=$(ip -4 addr show "$WIFI_IF" 2>/dev/null | grep -oP 'inet \K[\d.]+' || echo "none")
ETH_IP=$(ip -4 addr show "$ETH_IF" 2>/dev/null | grep -oP 'inet \K[\d.]+' || echo "none")
PUBLIC_IP=$(curl -m 5 -fs https://api.ipify.org 2>/dev/null || echo "unreachable")

# GeoIP + ISP + Location from public IP
if [ "$PUBLIC_IP" != "unreachable" ]; then
    GEOJSON=$(curl -m 5 -fs https://ipinfo.io/json 2>/dev/null || echo "{}")
    ISP=$(echo "$GEOJSON" | jq -r '.org // "unknown"' 2>/dev/null || echo "unknown")
    LOCATION=$(echo "$GEOJSON" | jq -r '"\(.city // "?"), \(.region // "?"), \(.country // "?")"' 2>/dev/null || echo "unknown")
    TIMEZONE=$(echo "$GEOJSON" | jq -r '.timezone // "unknown"' 2>/dev/null || echo "unknown")
else
    ISP="unreachable"
    LOCATION="unreachable"
    TIMEZONE="unreachable"
fi

# WiFi details
WIFI_SSID=$(iw dev "$WIFI_IF" link 2>/dev/null | grep "SSID" | awk '{print $2}' || echo "none")
WIFI_SIGNAL=$(iw dev "$WIFI_IF" link 2>/dev/null | grep "signal" | awk '{print $2, $3}' || echo "none")
WIFI_FREQ=$(iw dev "$WIFI_IF" link 2>/dev/null | grep "freq" | awk '{print $2}' | awk '{printf "%.1f GHz", $1/1000}' || echo "none")

# Gateway
GATEWAY=$(ip route 2>/dev/null | grep default | head -1 | awk '{print $3}' || echo "none")

# DNS
DNS_SERVERS=$(resolvectl dns 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | paste -sd ',' || echo "none")
DNS_TEST=$(nslookup discord.com 2>/dev/null | grep "Address" | tail -1 | awk '{print $2}' || echo "fail")

# DHCP
DHCP_LEASES=$(cat /var/lib/dhcpcd/*.lease 2>/dev/null | grep "dhcp_server" | tail -1 | awk '{print $2}' || echo "unknown")

# Ping tests
PING_GATEWAY=$(ping -c 1 -W 2 "$GATEWAY" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1 " ms"}' || echo "fail")
PING_INTERNET=$(ping -c 1 -W 2 1.1.1.1 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1 " ms"}' || echo "fail")

# Detect problems
PROBLEMS=""
[ "$WIFI_IP" = "none" ] && [ -n "$WIFI_IF" ] && PROBLEMS+="WiFi has no IP. "
[ "$ETH_IP" = "none" ] && [ -n "$ETH_IF" ] && PROBLEMS+="Ethernet has no IP. "
[ "$PUBLIC_IP" = "unreachable" ] && PROBLEMS+="No internet access. "
[ "$DNS_TEST" = "fail" ] && PROBLEMS+="DNS resolution failed. "

if [ -z "$PROBLEMS" ]; then
    exit 0
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg wifi_if "$WIFI_IF" \
  --arg wifi_ssid "$WIFI_SSID" \
  --arg wifi_ip "$WIFI_IP" \
  --arg wifi_signal "$WIFI_SIGNAL" \
  --arg wifi_freq "$WIFI_FREQ" \
  --arg wifi_mac "$WIFI_MAC" \
  --arg eth_if "$ETH_IF" \
  --arg eth_ip "$ETH_IP" \
  --arg eth_mac "$ETH_MAC" \
  --arg public_ip "$PUBLIC_IP" \
  --arg isp "$ISP" \
  --arg location "$LOCATION" \
  --arg timezone "$TIMEZONE" \
  --arg gateway "$GATEWAY" \
  --arg dns_servers "$DNS_SERVERS" \
  --arg dns_test "$DNS_TEST" \
  --arg dhcp_leases "$DHCP_LEASES" \
  --arg ping_gateway "$PING_GATEWAY" \
  --arg ping_internet "$PING_INTERNET" \
  --arg problems "$PROBLEMS" \
'{
  "content": null,
  "embeds": [{
    "title": "Network Issues",
    "color": 16750848,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Problems", "value": $problems, "inline": false},
      {"name": "WiFi Interface", "value": ($wifi_if // "none"), "inline": true},
      {"name": "WiFi SSID", "value": $wifi_ssid, "inline": true},
      {"name": "WiFi IP", "value": $wifi_ip, "inline": true},
      {"name": "WiFi MAC", "value": $wifi_mac, "inline": true},
      {"name": "WiFi Signal", "value": $wifi_signal, "inline": true},
      {"name": "WiFi Frequency", "value": $wifi_freq, "inline": true},
      {"name": "Ethernet IP", "value": $eth_ip, "inline": true},
      {"name": "Ethernet MAC", "value": $eth_mac, "inline": true},
      {"name": "Public IP", "value": $public_ip, "inline": true},
      {"name": "ISP", "value": $isp, "inline": true},
      {"name": "Location", "value": $location, "inline": true},
      {"name": "Timezone", "value": $timezone, "inline": true},
      {"name": "Gateway", "value": $gateway, "inline": true},
      {"name": "DNS Servers", "value": $dns_servers, "inline": true},
      {"name": "DNS Test (discord.com)", "value": $dns_test, "inline": true},
      {"name": "DHCP Server", "value": $dhcp_leases, "inline": true},
      {"name": "Ping Gateway", "value": $ping_gateway, "inline": true},
      {"name": "Ping Internet", "value": $ping_internet, "inline": true}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
