#!/usr/bin/env bash

set -euo pipefail

# The known MAC address of the camera (can be overridden as first argument)
MAC_ADDRESS="${1:-d8:32:14:b6:f2:1c}"

echo "[*] Scanning network for MAC address: ${MAC_ADDRESS}..."

IP_LIST=$(arp -a | grep -i "${MAC_ADDRESS}" | awk -F '[()]' '{print $2}' || true)
IP_ADDRESS=""

for IP in $IP_LIST; do
    # Check if the RTSP port 554 is actually open
    if nc -z -G 1 "$IP" 554 2>/dev/null; then
        IP_ADDRESS=$IP
        break
    fi
done

if [ -n "${IP_ADDRESS}" ]; then
    >&2 echo "[+] SUCCESS! Camera found."
    >&2 echo "[+] Active IP Address: ${IP_ADDRESS}"
    >&2 echo "--------------------------------------------------"
    >&2 echo "Here are your generated RTSP URLs for VLC/MediaMTX:"
    >&2 echo "  rtsp://admin:admin123456@${IP_ADDRESS}:554/ch=1?subtype=0"
    >&2 echo "  rtsp://admin:admin123456@${IP_ADDRESS}:554/ch=1?subtype=1"
    >&2 echo "--------------------------------------------------"
    exit 0
else
    >&2 echo "[-] Camera not found in ARP table."
    >&2 echo "[*] Tip: Ensure the camera is plugged in and wait 30 seconds."
    >&2 echo "[*] Tip: If connected via USB LAN on Mac, ensure Internet Sharing is ON."
    exit 1
fi
