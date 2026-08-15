# Troubleshooting

## `cfg80211_*`, `wiphy_*` compile errors

Do not build only `backports/drivers/realtek/rtl8821CU`. That bypasses Hardkernel's backports include layer. Build from the kernel root with:

```bash
make ARCH=arm M=backports KCFLAGS="-fno-pie -fno-PIE" modules
```

## `Unknown symbol _GLOBAL_OFFSET_TABLE_`

The generated module contains PIE/GOT relocations. Clean the old objects and rebuild with `KCFLAGS="-fno-pie -fno-PIE"`.

Verify that this prints nothing:

```bash
nm -u 8821cu.ko | grep GLOBAL_OFFSET
```

## `rtw_led_ctrl` invalid for parameter

An older `/etc/modprobe.d/8821cu.conf` may contain `options 8821cu rtw_led_ctrl=1`. This Hardkernel driver does not accept that option. Remove/comment it, run `sudo depmod -a`, then load the module again.

## Scans work but WPA authentication times out on 5 GHz

On the tested TP-Link Archer AX72, the adapter could associate at 5240 MHz but the WPA handshake timed out. Restricting wpa_supplicant to 2.4 GHz solved it without changing the router:

```text
freq_list=2412 2417 2422 2427 2432 2437 2442 2447 2452 2457 2462 2467 2472
```

Use `configure-wifi-24ghz.sh`.

## MATE reboot hangs while `sudo systemctl reboot` works

On the tested image, LightDM had an irrelevant NVIDIA hook in `/usr/share/lightdm/lightdm.conf.d/90-nvidia.conf` with `display-stopped-script=/sbin/prime-switch`. The log showed `/usr/bin/gpu-manager: not found`. Disabling that obsolete configuration fixed MATE's reboot path. This is not changed automatically because it is unrelated to the Wi-Fi driver.
