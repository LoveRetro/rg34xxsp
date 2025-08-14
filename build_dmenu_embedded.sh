#!/bin/sh
# build_dmenu_embedded.sh — builds dmenu.bin with embedded rootfs + assets

TARGET=dmenu.bin
OUTPUT_DIR=output
TMP_ROOTFS=~/buildroot/output/images/rootfs.ext2

mkdir -p "$OUTPUT_DIR"

# Prepare boot logo
if [ -f boot_logo.png ]; then
    convert boot_logo.png -type truecolor "$OUTPUT_DIR/boot_logo.bmp"
    gzip -f -n "$OUTPUT_DIR/boot_logo.bmp"
fi

# Prepare installing/updating screens (strip BMP header)
for f in installing updating; do
    if [ -f "$f.bmp" ]; then
        dd if="$f.bmp" of="$OUTPUT_DIR/$f" bs=1 skip=64
    fi
done

# Copy rootfs to work on it
WORK_ROOTFS="$OUTPUT_DIR/rootfs.ext2"
cp "$TMP_ROOTFS" "$WORK_ROOTFS"

# Mount rootfs
MOUNTPOINT="$OUTPUT_DIR/mount"
mkdir -p "$MOUNTPOINT"
sudo mount -o loop "$WORK_ROOTFS" "$MOUNTPOINT"

# Copy assets into rootfs
sudo mkdir -p "$MOUNTPOINT/assets"
sudo cp "$OUTPUT_DIR/boot_logo.bmp.gz" "$MOUNTPOINT/assets/"
sudo cp "$OUTPUT_DIR/installing" "$MOUNTPOINT/assets/"
sudo cp "$OUTPUT_DIR/updating" "$MOUNTPOINT/assets/"

# Unmount rootfs
sudo umount "$MOUNTPOINT"
rmdir "$MOUNTPOINT"

# Create dmenu.bin: boot.sh + embedded rootfs
cat > "$TARGET" <<'EOF'
#!/bin/sh
# Embedded boot script for dmenu.bin

TMPDIR=/tmp/dmenu
ROOTFS="$TMPDIR/rootfs.ext2"

mkdir -p "$TMPDIR"

SCRIPT="$0"
BINARY_LINE=$(grep -n '^BINARY$' "$SCRIPT" | cut -d: -f1)
TAIL_LINE=$((BINARY_LINE + 1))

# Decode the embedded rootfs
tail -n +$TAIL_LINE "$SCRIPT" | uudecode -o "$ROOTFS"

# Mount the rootfs
MOUNTPOINT="$TMPDIR/root"
mkdir -p "$MOUNTPOINT"
mount -o loop "$ROOTFS" "$MOUNTPOINT"

# Enter the rootfs shell
chroot "$MOUNTPOINT" /bin/sh

# Cleanup after exit
umount "$MOUNTPOINT"
rm -rf "$TMPDIR"

BINARY
EOF

# Append uuencoded rootfs
uuencode "$WORK_ROOTFS" rootfs.ext2 >> "$TARGET"

chmod +x "$TARGET"
echo "Built $TARGET successfully with embedded assets!"
