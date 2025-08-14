#!/bin/sh
set -e

TARGET=/dmenu.bin
ASSET_DIR=/assets
ROOTFS=/mnt/rootfs
SDCARD_DIR=$ROOTFS/mnt/SDCARD
ZIP_FILE=/mnt/sdcard/NextUI.zip
MOUNT_FLAG="$ROOTFS/.mounted"
ZIP_FLAG="$ROOTFS/.NextUI_extracted"

mkdir -p "$ASSET_DIR"
mkdir -p "$ROOTFS"

# 1. Extract internal assets from dmenu.bin
if [ ! -f "$ASSET_DIR/data" ]; then
    awk '/^BINARY$/ {found=1; next} found {print}' "$TARGET" | uudecode -o "$ASSET_DIR/data"
    cd "$ASSET_DIR"
    unzip -o data
    rm data
    cd -
fi

# 2. Mount root filesystem
if [ ! -f "$MOUNT_FLAG" ]; then
    mount -o loop,rw /rootfs.ext2 "$ROOTFS"
    touch "$MOUNT_FLAG"
fi

# 3. Extract NextUI.zip into /mnt/SDCARD inside mounted rootfs
if [ -f "$ZIP_FILE" ] && [ ! -f "$ZIP_FLAG" ]; then
    mkdir -p "$SDCARD_DIR"
    unzip -o "$ZIP_FILE" -d "$SDCARD_DIR"
    touch "$ZIP_FLAG"
fi

"$SDCARD_DIR/.system/rg34xxsp/bin/nextui.elf"

echo "Boot complete."
