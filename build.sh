#!/bin/bash
#
# hanoip-kernel build script
#
# Flow:
#   1) choose config source:
#        1) fresh  - delete old .config, run hanoip_defconfig
#        2) reuse  - keep last out/.config (oldconfig)
#   2) edit out/.config in menuconfig  (save&exit to continue)  [TTY only]
#   3) make reconciles .config (oldconfig/syncconfig) and builds the kernel
#
# Interactive choice + menuconfig run only when stdin is a TTY; a non-TTY run
# does a fresh defconfig + build (CI-safe, never blocks on input).
#
set -euo pipefail

export ARCH=arm64
export SUBARCH=arm64

TOOLCHAIN="/home/rani/clang/bin"
OUT_DIR="out"
JOBS="$(nproc --all)"
DEFCONFIG="hanoip_defconfig"

# Make variables (matches the manual invocation).
MAKE_ARGS=(
	ARCH=arm64
	CC="$TOOLCHAIN/clang"
	CLANG_TRIPLE=aarch64-linux-gnu-
	LD="$TOOLCHAIN/ld.lld"
	AR="$TOOLCHAIN/llvm-ar"
	NM="$TOOLCHAIN/llvm-nm"
	OBJCOPY="$TOOLCHAIN/llvm-objcopy"
	OBJDUMP="$TOOLCHAIN/llvm-objdump"
	STRIP="$TOOLCHAIN/llvm-strip"
	CROSS_COMPILE="$TOOLCHAIN/aarch64-linux-gnu-"
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
	LLVM=1
	LLVM_IAS=1
	KCFLAGS="-Wno-error -Wno-unknown-warning-option -Wno-incompatible-pointer-types"
)

# --- 1) choose fresh defconfig or reuse last .config ---
FRESH=1   # default
if [ -t 0 ]; then
	echo
	echo "Select config source:"
	echo "  1) fresh  - delete old .config and run $DEFCONFIG"
	echo "  2) reuse  - keep last out/.config (oldconfig) and edit"
	echo -n "choice [1/2] (default 1): "
	if ! read -r choice; then choice=""; fi
	case "$choice" in
		2|reuse)
			if [ -f "$OUT_DIR/.config" ]; then
				FRESH=0
			else
				echo ">> no existing .config; using fresh defconfig"
				FRESH=1
			fi
			;;
		*)
			FRESH=1
			;;
	esac
else
	echo ">> non-TTY: fresh defconfig (CI-safe)"
	FRESH=1
fi

if [ "$FRESH" = "1" ]; then
	echo ">> fresh defconfig: resetting $OUT_DIR"
	rm -rf "$OUT_DIR"
	mkdir -p "$OUT_DIR"
	echo ">> defconfig"
	make O="$OUT_DIR" hanoip_defconfig "${MAKE_ARGS[@]}"
else
	mkdir -p "$OUT_DIR"
	echo ">> reusing last $OUT_DIR/.config (oldconfig)"
fi

# --- 2) let the user tweak .config (interactive only) ---
if [ -t 0 ] && [ -f "$OUT_DIR/.config" ]; then
	echo ">> out/.config ready - edit it now (Save&Exit to continue, or just Exit to keep)"
	make O="$OUT_DIR" menuconfig "${MAKE_ARGS[@]}" 2>/dev/null \
		|| make O="$OUT_DIR" nconfig "${MAKE_ARGS[@]}" 2>/dev/null \
		|| "${EDITOR:-vi}" "$OUT_DIR/.config" || true
fi

# --- 3) reconcile .config (oldconfig) then build ---
echo ">> oldconfig (reconcile .config with Kconfig - answers new symbols with defaults)"
make O="$OUT_DIR" olddefconfig "${MAKE_ARGS[@]}" >/dev/null 2>&1 || true

echo ">> building kernel + modules  (-j${JOBS})  ->  $OUT_DIR/arch/arm64/boot/Image.gz"
make O="$OUT_DIR" -j"$JOBS" "${MAKE_ARGS[@]}"

echo ">> building dtbs + dtbo.img"
make O="$OUT_DIR" -j"$JOBS" "${MAKE_ARGS[@]}" dtbs dtbo.img

echo ">> build artifacts:"
ls -l "$OUT_DIR/arch/arm64/boot/Image" \
	"$OUT_DIR/arch/arm64/boot/Image.gz" \
	"$OUT_DIR/arch/arm64/boot/dts/qcom/sdmmagpie-hanoi-base.dtb" \
	"$OUT_DIR/arch/arm64/boot/dtbo.img" 2>/dev/null || true
echo ">> done."
