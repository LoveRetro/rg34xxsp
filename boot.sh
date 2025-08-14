#!/bin/sh
# boot.sh — extracts assets from dmenu.bin, mounts rootfs, and starts the UI

TARGET=/dmenu.bin
ASSET_DIR=/assets
ROOTFS_MNT=/mnt/rootfs
UI_BIN=/usr/bin/my_ui   # Path inside rootfs

mkdir -p "$ASSET_DIR" "$ROOTFS_MNT"

# 1. Extract assets if not already done
if [ ! -f "$ASSET_DIR/data" ]; then
    awk '/^BINARY$/ {found=1; next} found {print}' "$TARGET" | uudecode -o "$ASSET_DIR/data"

    cd "$ASSET_DIR"
    unzip -o data
    rm data
    cd -
fi

# 2. Decompress boot logo if needed
if [ -f "$ASSET_DIR/boot_logo.bmp.gz" ]; then
    gunzip -f "$ASSET_DIR/boot_logo.bmp.gz"
fi

echo "Assets extracted. Mounting root filesystem..."

# 3. Mount rootfs.ext2
if [ -f "$ASSET_DIR/rootfs.ext2" ]; then
    mount -o loop "$ASSET_DIR/rootfs.ext2" "$ROOTFS_MNT"
else
    echo "Error: rootfs.ext2 not found in $ASSET_DIR"
    exit 1
fi

echo "Root filesystem mounted at $ROOTFS_MNT"

# 4. Launch UI inside rootfs
if [ -x "$ROOTFS_MNT$UI_BIN" ]; then
    echo "Starting UI..."
    chroot "$ROOTFS_MNT" "$UI_BIN"
else
    echo "Error: UI binary $UI_BIN not found or not executable"
    exit 1
fi
