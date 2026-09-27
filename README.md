# CosmicFresh R6 - NetHunter Kernel for hanoip

Linux 4.14.206 arm64 | Kali NetHunter | CosmicFresh R6

## Device

| | |
|---|---|
| Device |moto g40 fusion/ g60 fusion hanoip (SDM730G) |
| SoC | Qualcomm Snapdragon 732G (sdmmagpie) |
| Kernel | 4.14.206 |
| Arch | arm64 |
| Build | NetHunter (CosmicFresh R6) |

## Features

- Fingerprint: Chipone (FPS_MMI)
- WiFi: qcacld-3.0 (Qualcomm) + rtl8821cu (USB)
- Toolchains: GCC 14.2.1 (aarch64), proton-clang 13, zyc-clang 16
- NetHunter kernel patches

## Modified Files

| File | Change |
|------|--------|
| `arch/arm64/Makefile:48` | `cc-option` guard for `-mno-fix-cortex-a53-843419` (clang compat) |
| `arch/arm64/configs/nethunter_defconfig.old` | Chipone fingerprint enabled, FPC disabled |
| `arch/arm64/boot/dts/qcom/sdmmagpie-hario-fps-overlay.dtsi` | FPC node `status = "disabled"` |
| `drivers/tty/diag/tty_diag.c:322,332` | Added `void` param (strict-prototypes fix) |
| `qca-wifi-host-cmn/target_if/core/src/target_if_main.c:91` | Added `void` param (strict-prototypes fix) |
| `qca-wifi-host-cmn/hif/src/ce/ce_service_legacy.c:1320` | Added `void` param (strict-prototypes fix) |
| `kali-nethunter-kernel-builder/build.sh` | `gen_defconfig` helper + `CC=clang` path |
| `kali-nethunter-kernel-builder/local.config` | zyc-clang 16 default, `CONFIG=nethunter_defconfig.old` |

## Build

```bash
cd kali-nethunter-kernel-builder
./build.sh
```

Select option 3 (make kernel). Answer `Y` to config edit.

Output: `out/arch/arm64/boot/Image.gz`

## Repack

```bash
cd /home/rani/bootimg-work
cp <out>/arch/arm64/boot/Image.gz .
/usr/local/bin/magiskboot unpack boot.img
/usr/local/bin/magiskboot repack boot.img nethunter-boot-new.img
```

## Flash

```
fastboot flash boot nethunter-boot-new.img
```

## AnyKernel3 Release

See `CosmicFresh/` for the AnyKernel3 flashable zip template.
