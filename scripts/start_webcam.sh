#!/usr/bin/env bash

# Stream webcam to MediaMTX via RTSP for local testing.
# Usage: ./scripts/stream_webcam.sh [device_index] [stream_path]
set -euo pipefail

DEVICE="${1:-0}"
STREAM_PATH="${2:-tenda_cp7_main}"
MEDIAMTX_URL="rtsp://admin:cognibrew@localhost:8554/${STREAM_PATH}"

# FFmpeg pre-flight checks
if ! command -v ffmpeg &>/dev/null; then
    echo "[!] ffmpeg not found. please visit: https://www.ffmpeg.org/download.html"
    exit 1
fi

# Check MediaMTX server is running
if ! nc -z localhost 8554; then
    echo "[!] MediaMTX server is not running. "
    echo "    Please start 'docker compose up -d' first."
    exit 1
fi

# Check .env file that must be set MEDIAMTX_CONFIG to mediamtx-webcam ONLY!!!
if ! grep -q "MEDIAMTX_CONFIG=mediamtx-webcam" .env; then
    echo "[!] MEDIAMTX_CONFIG is not set to mediamtx-webcam."
    echo "    Please set it to mediamtx-webcam in .env file."
    echo "    and run 'docker compose up -d' again."
    exit 1
fi

# List available devices
echo "[*] Available capture devices:"
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -E "^\[AVFoundation" || true
echo ""
echo "[*] Using device [${DEVICE}] --> ${MEDIAMTX_URL}"
echo "[*] Press Ctrl+C to stop."
echo ""

# Stream
ffmpeg -f avfoundation -framerate 30 -video_size 640x480 -i "${DEVICE}" \
    -pix_fmt yuv420p \
    -c:v libx264 -preset ultrafast -tune zerolatency \
    -r 15 -fps_mode cfr \
    -rtsp_transport tcp -f rtsp "${MEDIAMTX_URL}"
