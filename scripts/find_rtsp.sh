#!/usr/bin/env bash

set -euo pipefail

# The known MAC address of the camera 
# can be overridden as first argument, for example:
# ./scripts/find_rtsp.sh 00:11:22:33:44:55
MAC_ADDRESS="${1:-d8:32:14:b6:f2:1c}"

# Warning if MAC address is 'd8:32:14:b6:f2:1c'
if [ "${MAC_ADDRESS}" = "d8:32:14:b6:f2:1c" ]; then
    echo "[!] Warning: MAC address is 'd8:32:14:b6:f2:1c'."
    echo "    This is the default MAC address."
    echo "    Please change the MAC address to your camera's MAC address."
    echo "    You can find the MAC address on the camera's label."
    echo "    You can also use 'arp -a' to find the MAC address."
fi

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
    echo "[+] SUCCESS! Camera found."
    echo "[+] Active IP Address: ${IP_ADDRESS}"
    echo "--------------------------------------------------"
    echo "Here are your generated RTSP URLs for VLC/MediaMTX:"
    echo "  rtsp://admin:admin123456@${IP_ADDRESS}:554/ch=1?subtype=0"
    echo "  rtsp://admin:admin123456@${IP_ADDRESS}:554/ch=1?subtype=1"
    echo "--------------------------------------------------"
    exit 0
else
    echo "[-] Camera not found in ARP table."
    echo "[*] Tip: Ensure the camera is plugged in and wait 30 seconds."
    echo "[*] Tip: If connected via USB LAN on Mac, ensure Internet Sharing is ON."
    exit 1
fi
