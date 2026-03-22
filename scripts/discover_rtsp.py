import argparse
import logging
import re
import socket
import subprocess
import sys
from urllib.parse import urlparse

from onvif import ONVIFCamera
from onvif.exceptions import ONVIFError

# Suppress noisy IPv6 multicast warnings
logging.getLogger("threading").setLevel(logging.ERROR)
logging.getLogger("wsdiscovery").setLevel(logging.ERROR)


def auto_discover_onvif() -> list[dict]:
    try:
        from wsdiscovery import WSDiscovery
        from wsdiscovery.scope import Scope
    except ImportError:
        print(
            "[ERROR] WSDiscovery not installed. Run: pip install WSDiscovery"
        )
        sys.exit(1)

    print("Searching for ONVIF cameras via WS-Discovery...\n")

    wsd = WSDiscovery()
    wsd.start()

    # Search for ONVIF NetworkVideoTransmitter devices
    # Pass Scope objects, not raw strings
    services = wsd.searchServices(
        scopes=[Scope("onvif://www.onvif.org")],
        timeout=5,
    )
    wsd.stop()

    if not services:
        print("  [NOT FOUND] No ONVIF cameras found on the network.")
        print(
            "     Make sure your camera is powered on and connected to WiFi."
        )
        return []

    cameras: list[dict] = []
    for i, service in enumerate(services):
        xaddrs = service.getXAddrs()
        scopes = service.getScopes()

        # Extract IP and port from xaddrs
        for xaddr in xaddrs:
            parsed = urlparse(xaddr)
            ip = parsed.hostname
            port = parsed.port or 80

            # Extract camera name/model from scopes
            name = "Unknown"
            for scope in scopes:
                scope_str = str(scope)
                match = re.search(r"/name/(.+)", scope_str)
                if match:
                    name = match.group(1)
                    break
                match = re.search(r"/hardware/(.+)", scope_str)
                if match:
                    name = match.group(1)
                    break

            camera = {"ip": ip, "port": port, "name": name, "xaddr": xaddr}
            cameras.append(camera)
            print(f"  [FOUND] Camera {i + 1}: {name}")
            print(f"     IP:   {ip}")
            print(f"     Port: {port}")
            print(f"     URL:  {xaddr}")
            print()

    return cameras


def scan_network_for_cameras(
    subnet: str,
    ports: list[int] | None = None,
) -> list[dict]:
    if ports is None:
        ports = [554, 8554, 80]

    print(f"Scanning {subnet} for cameras (ports {ports})...")

    # Get ARP table entries
    try:
        result = subprocess.run(
            ["arp", "-a"], capture_output=True, text=True, check=True
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(
            "  [WARN] Could not read ARP table. "
            + "Try pinging the broadcast address first."
        )
        return []

    candidates: list[dict] = []
    for line in result.stdout.splitlines():
        # Parse IP from ARP output: ? (192.168.1.xxx) at ...
        if "(" not in line or ")" not in line:
            continue
        ip = line.split("(")[1].split(")")[0]
        if not ip.startswith(subnet.rsplit(".", 1)[0]):
            continue

        open_ports: list[int] = []
        for port in ports:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1.5)
            try:
                sock.connect((ip, port))
                open_ports.append(port)
            except (socket.timeout, ConnectionRefusedError, OSError):
                pass
            finally:
                sock.close()

        if open_ports:
            candidates.append({"ip": ip, "ports": open_ports})
            print(f"  [FOUND] {ip} -- open ports: {open_ports}")

    if not candidates:
        print("  [NOT FOUND] No cameras found on the network.")

    return candidates


def discover_rtsp(host: str, port: int, username: str, password: str) -> None:
    """Connect to a camera via ONVIF and retrieve RTSP stream URIs."""
    print(f"\nConnecting to camera at {host}:{port}...")

    try:
        cam = ONVIFCamera(host, port, username, password)
    except ONVIFError as e:
        print(f"\n[ERROR] Failed to connect: {e}")
        print("\nTroubleshooting tips:")
        print(f"  1. Verify the camera is reachable:  ping {host}")
        print("  2. Check ONVIF port (try 80, 6688, 8080):  --port <PORT>")
        print("  3. Verify credentials:  --user <USER> --password <PASS>")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Unexpected error: {e}")
        sys.exit(1)

    try:
        media_service = cam.create_media_service()
        profiles = media_service.GetProfiles()
    except ONVIFError as e:
        print(f"\n[ERROR] Failed to get media profiles: {e}")
        sys.exit(1)

    print(f"Found {len(profiles)} profile(s):\n")
    for profile in profiles:
        try:
            stream_uri = media_service.GetStreamUri(
                {
                    "StreamSetup": {
                        "Stream": "RTP-Unicast",
                        "Transport": {"Protocol": "RTSP"},
                    },
                    "ProfileToken": profile.token,
                }
            )
            print(f"  Profile: {profile.Name}")
            print(f"  URI:     {stream_uri.Uri}")
            print()
        except ONVIFError as e:
            print(f"  Profile: {profile.Name}")
            print(f"  [WARN] Could not get stream URI: {e}")
            print()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("host", nargs="?", help="Camera IP address")
    parser.add_argument(
        "--port", type=int, default=80, help="ONVIF port (default: 80)"
    )
    parser.add_argument(
        "--user", default="admin", help="Username (default: admin)"
    )
    parser.add_argument(
        "--password",
        default="admin123456",
        help="Password (default: admin123456)",
    )
    parser.add_argument(
        "--auto",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Auto-discover cameras using WS-Discovery (default: True)",
    )
    parser.add_argument(
        "--scan",
        metavar="SUBNET",
        help="Scan the network for cameras by port (e.g. 192.168.1.0)",
    )
    args = parser.parse_args()

    if args.auto:
        cameras = auto_discover_onvif()
        if not args.host and cameras:
            args.host = cameras[0]["ip"]
            args.port = cameras[0]["port"]
            print(f"Auto-selected: {args.host}:{args.port}")
    elif args.scan:
        candidates = scan_network_for_cameras(args.scan)
        if not args.host and candidates:
            args.host = candidates[0]["ip"]
            print(f"\nAuto-selected camera: {args.host}")

    if not args.host:
        parser.error(
            "please provide a camera IP, use --auto, or use --scan to find one"
        )

    discover_rtsp(args.host, args.port, args.user, args.password)
