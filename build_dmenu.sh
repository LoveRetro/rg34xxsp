#!/bin/sh
# build_dmenu.sh — builds dmenu.bin with embedded rootfs

TARGET=dmenu.bin
OUTPUT_DIR=output
TMP_ROOTFS=~/buildroot/output/images/rootfs.ext2

mkdir -p "$OUTPUT_DIR"

# Convert boot logo to gzipped BMP
if [ -f boot_logo.png ]; then
    convert boot_logo.png -type truecolor "$OUTPUT_DIR/boot_logo.bmp"
    gzip -f -n "$OUTPUT_DIR/boot_logo.bmp"
fi

# Prepare installing/updating screens (strip BMP header)
for f in installing updating; do
    if [ -f "$f.bmp" ] && [ ! -f "$OUTPUT_DIR/$f" ]; then
        dd if="$f.bmp" of="$OUTPUT_DIR/$f" bs=1 skip=64
    fi
done

# Package screens into a single zip named 'data'
cd "$OUTPUT_DIR"
if [ ! -f data ]; then
    zip -r data.zip installing updating
    mv data.zip data
fi
cd ..

# Copy rootfs
cp "$TMP_ROOTFS" "$OUTPUT_DIR/"

# Write boot.sh + binary section to dmenu.bin
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

# Append the uuencoded rootfs
uuencode "$OUTPUT_DIR/rootfs.ext2" rootfs.ext2 >> "$TARGET"

chmod +x "$TARGET"
echo "Built $TARGET successfully."
