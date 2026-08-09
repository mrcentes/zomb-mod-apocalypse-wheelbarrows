#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MOD_DIR="$ROOT_DIR/mods/ApocalypseWheelbarrows/42"
OUTPUT_DIR="$HOME/Zomboid/Workshop/ApocalypseWheelbarrows"
CONTENT_DIR="$OUTPUT_DIR/contents/mods/ApocalypseWheelbarrows"
PREVIEW_SRC="$MOD_DIR/poster.png"
PREVIEW_DEST="$OUTPUT_DIR/preview.png"

if [ ! -d "$MOD_DIR" ]; then
    echo "Missing mod directory: $MOD_DIR" >&2
    exit 1
fi

mkdir -p "$CONTENT_DIR"
rm -rf "$CONTENT_DIR/42"
cp -R "$MOD_DIR" "$CONTENT_DIR/"

if [ -f "$PREVIEW_SRC" ]; then
    cp "$PREVIEW_SRC" "$PREVIEW_DEST"
fi

find "$ROOT_DIR" -name '.DS_Store' -type f -delete

echo "Workshop package refreshed at: $OUTPUT_DIR"
