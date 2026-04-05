#!/usr/bin/env bash

# Stream webcam to MediaMTX via RTSP for local testing.
# Usage: ./scripts/stream_webcam.sh [device_index] [stream_path]
set -euo pipefail

DEVICE="${1:-0}"
STREAM_PATH="${2:-tenda_cp7_main}"
MEDIAMTX_URL="rtsp://admin:cognibrew@localhost:8554/${STREAM_PATH}"

# Pre-flight checks
if ! command -v ffmpeg &>/dev/null; then
  echo "  ffmpeg not found. please visit: https://www.ffmpeg.org/download.html"
  exit 1
fi

# List available devices
echo "Available capture devices:"
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -E "^\[AVFoundation" || true
echo ""
echo ">  Using device [${DEVICE}] → ${MEDIAMTX_URL}"
echo "   Press Ctrl+C to stop."
echo ""

# Stream
ffmpeg -f avfoundation -framerate 30 -video_size 640x480 -i "${DEVICE}" \
  -pix_fmt yuv420p \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -r 15 -fps_mode cfr \
  -rtsp_transport tcp -f rtsp "${MEDIAMTX_URL}"
