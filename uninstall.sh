#!/usr/bin/env bash
set -euo pipefail
KVER="$(uname -r)"
MOD="/lib/modules/$KVER/kernel/drivers/net/wireless/realtek/rtl8821cu/8821cu.ko"
sudo modprobe -r 8821cu 2>/dev/null || true
sudo rm -f "$MOD" /etc/modules-load.d/8821cu.conf
sudo depmod -a "$KVER"
echo "8821cu module removed. Wi-Fi configuration files were left untouched."
