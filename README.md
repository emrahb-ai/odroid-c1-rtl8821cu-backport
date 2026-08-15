# RTL8821CU on ODROID-C1/C1+ (Hardkernel 3.10.107-11)

A practical installer for the Realtek **RTL8821CU / USB ID `0bda:c820`** Wi-Fi adapter on **ODROID-C1 / C1+** systems running Hardkernel's legacy **Linux 3.10.107-11 ARMv7** kernel.

## Fastest install

A tested prebuilt module is included at:

```text
prebuilt/3.10.107-11/armv7/8821cu.ko
```

For the tested kernel, `install.sh` uses this binary automatically, so users do **not** need to rebuild the whole Hardkernel backports tree.

```bash
git clone https://github.com/emrahb-ai/odroid-c1-rtl8821cu-backport.git
cd odroid-c1-rtl8821cu-backport
chmod +x *.sh
./install.sh
```

The prebuilt module was tested with:

- ODROID-C1 / C1+
- ARMv7
- Kernel: `3.10.107-11`
- USB adapter: `0bda:c820 Realtek Semiconductor Corp.`
- Driver: `v5.4.1_28754.20180921_COEX20180712-3232`
- vermagic: `3.10.107-11 SMP preempt mod_unload ARMv7`
- MD5: `4f96f2b96ba526d52f36e72990e8df78`
- WPA2-PSK (AES)
- 2.4 GHz connection tested successfully

After installation:

```bash
lsmod | grep 8821
ip link show wlan0
iw dev
```

## Build from source instead

The original reproducible build path remains available:

```bash
./install.sh --build
```

The source-build path fetches Hardkernel's `odroidc-3.10.y` tree and builds the RTL8821CU driver through Hardkernel's backports framework.

The working recipe is:

1. Use the running kernel configuration (`/proc/config.gz`).
2. Prepare Hardkernel's `odroidc-3.10.y` tree.
3. Use the running kernel's `Module.symvers`.
4. Enable Hardkernel backports + `CONFIG_RTL8821CU=m`.
5. Build with `M=backports`.
6. Disable PIE with `KCFLAGS="-fno-pie -fno-PIE"`.
7. Install `8821cu.ko` and run `depmod`.

## Configure Wi-Fi (2.4 GHz only)

On some modern dual-band access points, this old vendor driver can associate on 5 GHz but fail during WPA authentication. The helper below restricts association to 2.4 GHz without changing the router:

```bash
./configure-wifi-24ghz.sh
```

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
sudo iw dev wlan0 scan | grep -E 'SSID:|freq:'
```

## Removal

```bash
sudo ./uninstall.sh
```

## Important notes

- The prebuilt module is intentionally restricted to the exact tested kernel: `3.10.107-11` ARMv7.
- Do not use the prebuilt module on a different kernel unless you know exactly what you are doing.
- The installer validates `vermagic` before installation.
- If `modprobe 8821cu` reports `invalid for parameter rtw_led_ctrl`, remove/comment any old `options 8821cu rtw_led_ctrl=...` line under `/etc/modprobe.d/`.
- Back up production SD cards before making system changes.

See [Troubleshooting](docs/TROUBLESHOOTING.md) for the errors encountered during development.

## Türkçe kısa açıklama

Bu repo, ODROID-C1/C1+ üzerinde Hardkernel `3.10.107-11` kernelinde `0bda:c820` RTL8821CU USB Wi-Fi adaptörünü çalıştırmak için hazırlanmıştır. Aynı kerneli kullananlar için hazır çalışan `.ko` dosyası repoya eklenmiştir; `./install.sh` doğrudan bu modülü kurar. İsteyen kullanıcı `./install.sh --build` ile kaynaktan yeniden derleyebilir.

## Licensing / attribution

The prebuilt module reports GPL licensing through `modinfo`. Kernel/backports and Realtek driver code retain their upstream licensing. Scripts and original documentation in this repository are MIT licensed.
