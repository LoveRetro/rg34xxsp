#!/bin/sh
# Minimal boot.sh for dmenu.bin

TMPDIR=/tmp/dmenu
ROOTFS="$TMPDIR/rootfs.ext2"

# Create temp directory
mkdir -p "$TMPDIR"

# Extract the binary section from this script
# Everything after the line "BINARY" is the uuencoded rootfs
SCRIPT="$0"
BINARY_LINE=$(grep -n '^BINARY$' "$SCRIPT" | cut -d: -f1)
TAIL_LINE=$((BINARY_LINE + 1))

# Decode the uuencoded rootfs
tail -n +$TAIL_LINE "$SCRIPT" | uudecode -o "$ROOTFS"

# Mount the rootfs
MOUNTPOINT="$TMPDIR/root"
mkdir -p "$MOUNTPOINT"
mount -o loop "$ROOTFS" "$MOUNTPOINT"

# Switch root or run commands inside it
# For example, run a shell inside the new root
chroot "$MOUNTPOINT" /bin/sh

# Cleanup after exit
umount "$MOUNTPOINT"
rm -rf "$TMPDIR"
