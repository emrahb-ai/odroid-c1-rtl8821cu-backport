#!/usr/bin/env bash
set -u
echo '=== system ==='; uname -a; printf 'kernel: '; uname -r
echo; echo '=== USB ==='; lsusb 2>/dev/null | grep -Ei '0bda:c820|realtek' || true
echo; echo '=== module ==='; modinfo 8821cu 2>/dev/null | grep -E 'filename|version|vermagic|alias' || true; lsmod | grep 8821 || true
KO="$(modinfo -n 8821cu 2>/dev/null || true)"
if [[ -n "$KO" && -f "$KO" ]]; then echo; echo '=== GLOBAL_OFFSET check (should be empty) ==='; nm -u "$KO" 2>/dev/null | grep GLOBAL_OFFSET || true; fi
echo; echo '=== wireless ==='; ip link show wlan0 2>/dev/null || true; iw dev 2>/dev/null || true; iw dev wlan0 link 2>/dev/null || true
echo; echo '=== recent driver messages ==='; dmesg | grep -Ei '8821|rtl8821|wlan0|cfg80211' | tail -80 || true
