#!/usr/bin/env bash
set -euo pipefail
CONF="${WPA_CONF:-/etc/wpa_supplicant.conf}"
read -r -p "Wi-Fi SSID: " SSID
read -r -s -p "Wi-Fi password: " PASS
echo
command -v wpa_passphrase >/dev/null || { echo "wpa_passphrase is required." >&2; exit 1; }
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
wpa_passphrase "$SSID" "$PASS" > "$TMP"
sed -i '/^[[:space:]]*#psk=/d' "$TMP"
sed -i '/^}/i\        freq_list=2412 2417 2422 2427 2432 2437 2442 2447 2452 2457 2462 2467 2472' "$TMP"
sudo install -m 600 "$TMP" "$CONF"
if [[ -d /etc/network/interfaces.d ]]; then
  sudo tee /etc/network/interfaces.d/wlan0.cfg >/dev/null <<EON
allow-hotplug wlan0
auto wlan0
iface wlan0 inet dhcp
    wpa-conf $CONF
EON
fi
echo "Wrote $CONF and restricted association to 2.4 GHz."
echo "Test with: sudo ifdown wlan0 2>/dev/null || true; sudo ifup wlan0"
