# Cognibrew Edge
Edge deployment stack for the **Cognibrew** face-recognition platform.

## Services
| Service | Image | Purpose |
|---------|-------|---------|
| **MediaMTX** | `bluenviron/mediamtx:1.17.0` | RTSP relay / restream |
| **RabbitMQ** | `rabbitmq:4.2.5-management-alpine` | Message broker |
| **Qdrant** | `qdrant/qdrant:v1.17` | Vector similarity search |
| **Inference Server** | `cognibrew-inference-server` | Frame capture --> face embedding extraction |
| **Recognition Service** | `cognibrew-recognition-service` | Embedding --> identity matching |
| **Version Manager** | `cognibrew-version-manager` | Rolling updates & cloud sync |

## Quick Start

### 1. Find Your Camera IP

**IP Camera (Tenda CP7)**

Use the bundled ARP scanner to locate the camera on your network:

```bash
./scripts/find_rtsp.sh                     # uses default MAC d8:32:14:b6:f2:1c
./scripts/find_rtsp.sh AA:BB:CC:DD:EE:FF   # custom MAC address
```

The script prints ready-to-use RTSP URLs when the camera is found.

**Webcam (local testing)**

Stream your Mac's webcam into MediaMTX via FFmpeg:

1. Set `MEDIAMTX_CONFIG=mediamtx-webcam` in `.env`
2. Run: `docker compose up -d`
3. Run the script:

```bash
./scripts/stream_webcam.sh              # device 0, publishes to tenda_cp7_main
./scripts/stream_webcam.sh 1            # alternate device index
./scripts/stream_webcam.sh 0 my_stream  # custom stream path
```

> **Important:** The script runs on your **host Mac** and publishes to `localhost:8554` (the port-mapped MediaMTX container).

### 2. Configure MediaMTX

Three preset configurations live in `configs/`:

| Config file | `MEDIAMTX_CONFIG` value | Use case |
|-------------|------------------------|----------|
| `mediamtx-mac.yml` | `mediamtx-mac` (default) | Tenda CP7 via USB-Ethernet (`192.168.2.2`) |
| `mediamtx-wifi.yml` | `mediamtx-wifi` | Tenda CP7 over Wi-Fi (`192.168.1.121`) |
| `mediamtx-webcam.yml` | `mediamtx-webcam` | Local webcam via `stream_webcam.sh` |

Set the `MEDIAMTX_CONFIG` variable in your `.env` to pick a config:

```bash
MEDIAMTX_CONFIG=mediamtx-webcam
```

> Each config file only overrides non-default values.
> Full reference: <https://github.com/bluenviron/mediamtx/blob/main/mediamtx.yml>

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` to match your setup. Key variables:

| Group | Variable | Default |
|-------|----------|---------|
| **Shared** | `RABBITMQ_USERNAME` / `RABBITMQ_PASSWORD` | `guest` / `guest` |
| **MediaMTX** | `MEDIAMTX_CONFIG` | `mediamtx-mac` |
| **MediaMTX** | `MEDIAMTX_STREAM_PATH` | `tenda_cp7_main` |
| **Inference** | `INF_STREAM_SKIP_FRAME` | `5` |
| **Inference** | `INF_STREAM_APPLY_DIFF` / `INF_STREAM_DIFF_THRESHOLD` | `true` / `5.0` |
| **Inference** | `INF_MODEL_NAME` | `buffalo_sc` |
| **Recognition** | `REC_MODEL_SIMILARITY_THRESHOLD` | `0.50` |
| **Version Mgr** | `VMNG_DOCKER_TARGET_LABEL` | `cognibrew.service=recognition` |
| **Version Mgr** | `VMNG_DOCKER_HEALTH_TIMEOUT_S` / `VMNG_DOCKER_HEALTH_POLL_S` | `30` / `1` |
| **Version Mgr** | `VMNG_SYNC_URL` | `http://localhost/api/v1/sync/bundle` |
| **Version Mgr** | `VMNG_SYNC_PAGE_SIZE` | `50` |
| **Version Mgr** | `VMNG_SYNC_SCHEDULE_TIME` / `VMNG_SYNC_CHECK_EVERY` | `01:00` / `60` |

### 4. Run Docker Compose

**Without GPU (Mac / CI):**

```bash
docker compose up -d
```

**With NVIDIA GPU (production server):**

```bash
docker compose -f compose.yaml -f compose.gpu.yaml up -d
```

> **Note:** GPU mode requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

### 5. Verify

| Service | URL |
|---------|-----|
| RabbitMQ Management | <http://localhost:15672> |
| Qdrant Dashboard | <http://localhost:6333/dashboard> |
| MediaMTX API | <http://localhost:9997/v3/paths/list> |
| Version Manager API | <http://localhost:8000/docs> |

### 6. Stop

```bash
docker compose down          # keep volumes
docker compose down -v       # remove volumes
```