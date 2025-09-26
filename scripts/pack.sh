#!/usr/bin/env bash
set -e
# Attempt to download sample video so it's included in the zip (non-fatal)
./scripts/download-sample.sh || echo "download script failed — continuing"

OUT=ai-video-platform-$(date +%Y%m%d-%H%M).zip
zip -r "$OUT" README.md backend docker scripts || true

echo "Created $OUT"
