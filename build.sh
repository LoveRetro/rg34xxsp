#!/bin/sh
set -e

# Paths
TARGET=dmenu.bin
OUTPUT=output
BUILDROOT_DIR=~/buildroot
ROOTFS="$BUILDROOT_DIR/output/images/rootfs.ext2"

# Make output directory
mkdir -p $OUTPUT

# 1. Run Buildroot to build root filesystem
echo "Building root filesystem with Buildroot..."
cd $BUILDROOT_DIR
make
cd -

# 2. Process bitmap files
for IMG in installing updating; do
    if [ ! -f $OUTPUT/$IMG ]; then
        dd skip=64 iflag=skip_bytes if=$IMG.bmp of=$OUTPUT/$IMG
    fi
done

# 3. Convert boot logo to BMP and gzip it
convert boot_logo.png -type truecolor $OUTPUT/boot_logo.bmp
gzip -f -n $OUTPUT/boot_logo.bmp

# 4. Package files into data archive
cd $OUTPUT
if [ ! -f data ]; then
    zip -r data.zip installing updating
    mv data.zip data
fi
cd ..

# 5. Copy root filesystem from Buildroot output
cp "$ROOTFS" $OUTPUT/

# 6. Build final dmenu.bin
cat boot.sh > $TARGET
echo BINARY >> $TARGET
uuencode $OUTPUT/data data >> $TARGET

echo "Build complete: $TARGET"
