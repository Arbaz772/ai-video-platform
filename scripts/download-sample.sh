#!/usr/bin/env bash
set -e
mkdir -p backend/static
OUT=backend/static/sample.mp4
# Public domain sample video (MDN flower sample)
URL="https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"

echo "Downloading sample video to $OUT..."
curl -L "$URL" -o "$OUT"
ls -lh "$OUT"

echo "Done. Start the app and play http://localhost:4000/static/sample.mp4"
