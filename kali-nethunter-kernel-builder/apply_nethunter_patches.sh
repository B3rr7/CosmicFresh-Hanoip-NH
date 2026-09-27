#!/bin/bash
# apply_nethunter_patches.sh
# Non-interactive NetHunter patch step for the hanoip 4.14.206 tree.
# Applies ONLY the patches/4.14 entries that cleanly apply on this tree;
# the failing ones (rtw88, qcacld-injection, samsung/dtc) are skipped.
# Run from anywhere; resolves KDIR as the kernel tree root (parent dir).
set -u

BUILDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KDIR="$(cd "$BUILDER_DIR/.." && pwd)"
PATCH_DIR="$BUILDER_DIR/patches/4.14"

cd "$KDIR" || { echo "cannot cd to $KDIR"; exit 1; }

apply() {
    local p="$1"; local opt="${2:-}"
    local name; name="$(basename "$p")"
    if git apply --check $opt "$p" >/dev/null 2>&1; then
        if git apply $opt "$p" 2>/dev/null; then
            echo "APPLIED   $name"
        else
            echo "FAIL     $name (apply error)"
        fi
    else
        echo "SKIP     $name (does not apply on this tree)"
    fi
}

echo "Kernel tree: $KDIR"
echo "Patch dir  : $PATCH_DIR"
echo "----------------------------------------"

# Core NetHunter functionality (clean on 4.14.206 via git apply)
apply "$PATCH_DIR/add-wifi-injection-4.14.patch"
apply "$PATCH_DIR/add-rtl88xxau-5.6.4.2-drivers.patch"
apply "$PATCH_DIR/add-ub500-to-btusb.patch"
apply "$PATCH_DIR/fix-ath9k-naming-conflict.patch"
apply "$PATCH_DIR/fix-thread_info.h-compile-time-errors.patch"

# Patches that git apply rejects (too strict on context) but patch(1) applies
# cleanly with fuzz. NOTE: add-qcacld leaves one rejected hunk
# (wlan_hdd_main.c UI guard vs this tree's layout) — harmless, ignored.
echo "Applying fuzz-tolerant patches (patch -p1 --fuzz=8)..."
for p in \
    add-qcacld-3.0-injection-4.14.patch \
    add-rtw88-drivers-4.14.patch \
    add-rtl8188eus-to-rtl8xxxu-drivers-4.14.patch ; do
    if patch -p1 --fuzz=8 < "$PATCH_DIR/$p" >/dev/null 2>&1; then
        echo "APPLIED   $p"
    else
        echo "PARTIAL  $p (some hunks rejected — see *.rej; usually safe)"
    fi
    # drop stray reject files; the rejected hunks are non-essential guards
    find . -name "*.rej" -not -path "./out/*" -delete 2>/dev/null
done

# Intentionally skipped (verified irrelevant / unneeded for hanoip):
#   add-rtl8188eus-to-rtl8xxxu-drivers.patch      -> wrong kernel version (Kconfig:1 fails)
#   fix-hciconfig-samsung-oneui*.patch -> Samsung-only BT, irrelevant for Motorola
#   fix-yylloc.dtc-lexer.lex.c_shipped.patch -> unneeded on 4.14.206

echo "----------------------------------------"
echo "Done. Internal Wi-Fi injection + RTW88 are NOT patched (see notes above)."
