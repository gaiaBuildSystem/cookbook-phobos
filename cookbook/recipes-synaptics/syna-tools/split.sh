#!/bin/bash

# Advanced script to split a rootfs image into sparse chunks with compression and metadata

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <rootfs.img> <rootfs.img.gz> <chunk_size_in_MB> <output_dir>"
    exit 1
fi

# Input arguments
ROOTFS_IMG=$1
ROOTFS_IMG_GZIPED=$2
CHUNK_SIZE_MB=$3
OUTPUT_DIR=$4

# Validate the input files
if [ ! -f "$ROOTFS_IMG" ]; then
    echo "Error: File '$ROOTFS_IMG' not found!"
    exit 1
fi

if [ ! -f "$ROOTFS_IMG_GZIPED" ]; then
    echo "Error: File '$ROOTFS_IMG_GZIPED' not found!"
    exit 1
fi

# Convert chunk size to bytes
CHUNK_SIZE_BYTES=$((CHUNK_SIZE_MB * 1024 * 1024))

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get base name without extension - properly handle any extension
FULL_BASENAME=$(basename "$ROOTFS_IMG_GZIPED")
BASE_NAME="${FULL_BASENAME%.*.*}"  # Remove .img.gz

# Check if the gzipped image already exceeds the size threshold
if [ "$(stat -c %s "$ROOTFS_IMG_GZIPED")" -gt "$CHUNK_SIZE_BYTES" ]; then
    echo "Gzipped image exceeds $CHUNK_SIZE_MB MB, need to sparse and split..."

    # Generate sparse image from the raw image
    SPARSE_IMG="${OUTPUT_DIR}/${BASE_NAME}_sparse.img"
    echo "Creating sparse image..."
    img2simg "$ROOTFS_IMG" "$SPARSE_IMG" 4096

    # Split the sparse image into chunks
    simg2simg "$SPARSE_IMG" "${OUTPUT_DIR}/${BASE_NAME}_chunk" "$CHUNK_SIZE_BYTES"
    rm -f "$SPARSE_IMG" # Remove the original sparse image

    # Rename chunks to follow the required pattern: name.subimg.0, name.subimg.1, etc.
    CHUNK_INDEX=0
    for CHUNK in "${OUTPUT_DIR}/${BASE_NAME}_chunk"*; do
        if [ -f "$CHUNK" ]; then
            mv "$CHUNK" "${OUTPUT_DIR}/${BASE_NAME}.subimg.${CHUNK_INDEX}"
            ((CHUNK_INDEX++))
        fi
    done
else
    echo "Gzipped image is within size limits, using as-is..."
    cp "$ROOTFS_IMG_GZIPED" "${OUTPUT_DIR}/${BASE_NAME}.subimg.gz"
fi

# Generate metadata
echo "Generating metadata..."
METADATA_FILE="${OUTPUT_DIR}/metadata_${BASE_NAME}.txt"
rm -f "$METADATA_FILE"
touch "$METADATA_FILE"

# List all generated files
for FILE in "${OUTPUT_DIR}/${BASE_NAME}.subimg."*; do
    if [ -f "$FILE" ]; then
        FILENAME=$(basename "$FILE")
        echo "$FILENAME" >> "$METADATA_FILE"
    fi
done

echo "Process complete. Output stored in '$OUTPUT_DIR'."
exit 0
