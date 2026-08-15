#!/usr/bin/env bash
set -euo pipefail

KVER="$(uname -r)"
EXPECTED_KVER="3.10.107-11"
SRC_DIR="${SRC_DIR:-$HOME/hardkernel-c1-kernel}"
BRANCH="${BRANCH:-odroidc-3.10.y}"
MOD_DEST="/lib/modules/$KVER/kernel/drivers/net/wireless/realtek/rtl8821cu"

if [[ $EUID -eq 0 ]]; then echo "Run this script as a normal user; it will use sudo when needed." >&2; exit 1; fi
if [[ "$KVER" != "$EXPECTED_KVER" && "${ALLOW_UNTESTED_KERNEL:-0}" != "1" ]]; then
  echo "Unsupported kernel: $KVER (tested: $EXPECTED_KVER)" >&2; exit 1
fi
for cmd in git make gcc zcat sed grep cp depmod modprobe nm modinfo; do command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }; done
[[ -r /proc/config.gz ]] || { echo "/proc/config.gz is required." >&2; exit 1; }
[[ -r "/usr/src/linux-$KVER/Module.symvers" ]] || { echo "Missing /usr/src/linux-$KVER/Module.symvers" >&2; exit 1; }

if [[ ! -d "$SRC_DIR/.git" ]]; then
  git clone --depth 1 --branch "$BRANCH" https://github.com/hardkernel/linux.git "$SRC_DIR"
fi
cd "$SRC_DIR"
zcat /proc/config.gz > .config
if grep -q '^CONFIG_LOCALVERSION=' .config; then sed -i 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-11"/' .config; else printf '%s\n' 'CONFIG_LOCALVERSION="-11"' >> .config; fi
yes '' | make ARCH=arm oldconfig >/dev/null || true

set_config() { local key="$1" value="$2"; sed -i "/^# ${key} is not set$/d;/^${key}=/d" .config; printf '%s=%s\n' "$key" "$value" >> .config; }
set_config CONFIG_BACKPORT_LINUX y
set_config CONFIG_BACKPORT_BPAUTO_USERSEL_BUILD_ALL y
set_config CONFIG_BACKPORT_CFG80211 y
set_config CONFIG_BACKPORT_MAC80211 y
set_config CONFIG_BACKPORT_WLAN y
set_config CONFIG_RTL8821CU m
yes '' | make ARCH=arm oldconfig >/dev/null || true

for required in 'CONFIG_BACKPORT_LINUX=y' 'CONFIG_BACKPORT_CFG80211=y' 'CONFIG_BACKPORT_MAC80211=y' 'CONFIG_BACKPORT_WLAN=y' 'CONFIG_RTL8821CU=m'; do
  grep -qx "$required" .config || { echo "Required config was not retained: $required" >&2; exit 1; }
done

make ARCH=arm prepare
make ARCH=arm modules_prepare
cp "/usr/src/linux-$KVER/Module.symvers" ./Module.symvers
JOBS="${JOBS:-2}"
make ARCH=arm M=backports -j"$JOBS" KCFLAGS="-fno-pie -fno-PIE" modules
KO="$SRC_DIR/backports/drivers/realtek/rtl8821CU/8821cu.ko"
[[ -f "$KO" ]] || { echo "Build finished but $KO was not created." >&2; exit 1; }
if nm -u "$KO" | grep -q _GLOBAL_OFFSET_TABLE_; then echo "Module contains _GLOBAL_OFFSET_TABLE_; refusing install." >&2; exit 1; fi
VERMAGIC="$(modinfo -F vermagic "$KO" || true)"
[[ "$VERMAGIC" == "$KVER"* ]] || { echo "Unexpected vermagic: $VERMAGIC" >&2; exit 1; }

sudo mkdir -p "$MOD_DEST"
sudo cp "$KO" "$MOD_DEST/8821cu.ko"
printf '%s\n' 8821cu | sudo tee /etc/modules-load.d/8821cu.conf >/dev/null
sudo depmod -a "$KVER"
if [[ -f /etc/modprobe.d/8821cu.conf ]] && grep -q 'rtw_led_ctrl' /etc/modprobe.d/8821cu.conf; then
  sudo cp /etc/modprobe.d/8821cu.conf /etc/modprobe.d/8821cu.conf.bak
  sudo sed -i '/rtw_led_ctrl/s/^/# disabled by odroid-c1-rtl8821cu-backport: /' /etc/modprobe.d/8821cu.conf
fi
sudo modprobe -r 8821cu 2>/dev/null || true
sudo modprobe 8821cu
echo "Installed successfully. Check: lsmod | grep 8821 ; ip link show wlan0 ; iw dev"
echo "For dual-band APs, run: ./configure-wifi-24ghz.sh"
