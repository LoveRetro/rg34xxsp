#!/bin/sh
# boot.sh — extracts assets from dmenu.bin and starts the system

TARGET=/dmenu.bin
ASSET_DIR=/assets

mkdir -p "$ASSET_DIR"

# Check if assets are already extracted
if [ ! -f "$ASSET_DIR/data" ]; then
    # Extract uuencoded data section
    awk '/^BINARY$/ {found=1; next} found {print}' "$TARGET" | uudecode -o "$ASSET_DIR/data"

    # Unpack ZIP
    cd "$ASSET_DIR"
    unzip -o data
    rm data
    cd -
fi

# Now $ASSET_DIR contains:
# - installing
# - updating
# - boot_logo.bmp.gz

# Example usage: decompress boot logo
if [ -f "$ASSET_DIR/boot_logo.bmp.gz" ]; then
    gunzip -f "$ASSET_DIR/boot_logo.bmp.gz"
fi

# Continue with your normal boot process here
# For example, mount rootfs, start init, etc.
# mount -o loop /rootfs.ext2 /mnt
# exec /mnt/init

echo "Assets extracted. Boot process can continue..."
