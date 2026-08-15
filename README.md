# RTL8821CU on ODROID-C1/C1+ (Hardkernel 3.10.107-11)

A reproducible installer for the Realtek **RTL8821CU / USB ID `0bda:c820`** Wi-Fi adapter on **ODROID-C1 / C1+** systems running Hardkernel's legacy **Linux 3.10.107-11 ARMv7** kernel.

This repository does **not** redistribute the Realtek driver source. The installer fetches Hardkernel's `odroidc-3.10.y` kernel tree and builds the `rtl8821CU` driver through Hardkernel's backports framework.

## Tested setup

- ODROID-C1 / C1+
- ARMv7
- Kernel: `3.10.107-11`
- USB adapter: `0bda:c820 Realtek Semiconductor Corp.`
- Driver produced: `8821cu.ko`
- Driver version observed: `v5.4.1_28754.20180921_COEX20180712-3232`
- WPA2-PSK (AES)
- 2.4 GHz connection tested successfully

## Why this exists

A normal out-of-tree RTL8821CU build on this old Hardkernel kernel runs into a mix of cfg80211/backports API mismatches. Building the driver directly from the subdirectory also bypasses Hardkernel's backports include layer. In addition, modern GCC toolchains may generate `_GLOBAL_OFFSET_TABLE_` relocations unless PIE is disabled explicitly.

The working recipe is:

1. Use the running kernel configuration (`/proc/config.gz`).
2. Prepare Hardkernel's `odroidc-3.10.y` tree.
3. Use the running kernel's `Module.symvers`.
4. Enable Hardkernel backports + `CONFIG_RTL8821CU=m`.
5. Build with `M=backports` (not the RTL8821CU subdirectory).
6. Disable PIE with `KCFLAGS="-fno-pie -fno-PIE"`.
7. Install `8821cu.ko` and run `depmod`.

## Quick install

```bash
./install.sh
```

The installer intentionally refuses unsupported kernels by default. The tested target is `3.10.107-11`.

After installation:

```bash
lsmod | grep 8821
ip link show wlan0
iw dev
```

For `0bda:c820`:

```bash
lsusb | grep -i '0bda:c820'
```

## Configure Wi-Fi (2.4 GHz only)

On some modern dual-band access points the old vendor driver can associate on 5 GHz but fail during WPA authentication. The helper below creates a WPA supplicant configuration that restricts association to 2.4 GHz while leaving the router untouched.

```bash
./configure-wifi-24ghz.sh
```

It prompts for the SSID and Wi-Fi password interactively and never stores the clear-text password in this repository.

The important setting is:

```text
freq_list=2412 2417 2422 2427 2432 2437 2442 2447 2452 2457 2462 2467 2472
```

## Diagnostics

```bash
./diagnose.sh
```

Useful manual checks:

```bash
modinfo 8821cu | grep -E 'filename|version|vermagic|alias'
nm -u $(modinfo -n 8821cu) | grep GLOBAL_OFFSET
readelf -r $(modinfo -n 8821cu) | grep GLOBAL_OFFSET
sudo iw dev wlan0 scan | grep -E 'SSID:|freq:'
```

For a correct build, the `GLOBAL_OFFSET` checks should return no output.

## Removal

```bash
sudo ./uninstall.sh
```

## Important notes

- This project is intentionally conservative and targets the exact legacy kernel we tested.
- It does not replace the kernel, bootloader, Device Tree, GPIO configuration, HDMI configuration, or existing application stack.
- Back up the SD card before modifying a production device.
- The build needs several GB of free space because Hardkernel's backports tree is compiled.
- If `modprobe 8821cu` says `invalid for parameter rtw_led_ctrl`, remove/comment any old `options 8821cu rtw_led_ctrl=...` line under `/etc/modprobe.d/`.

See [Troubleshooting](docs/TROUBLESHOOTING.md) for the errors encountered during development.

## Türkçe kısa açıklama

Bu repo ODROID-C1/C1+ üzerinde çalışan eski Hardkernel `3.10.107-11` kernelinde `0bda:c820` RTL8821CU USB Wi-Fi adaptörünü çalıştırmak için hazırlanmıştır. Router ayarlarını değiştirmeden yalnızca 2.4 GHz'e bağlanmak için `configure-wifi-24ghz.sh` kullanılabilir.

## Upstream / source attribution

The installer fetches Hardkernel's public Linux repository, branch `odroidc-3.10.y`. Driver and kernel/backports code retain their upstream licensing. The scripts and documentation in this repository are MIT licensed.
