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
Use `cp .env.example .env` to create a new environment file.

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

1. Set `MEDIAMTX_CONFIG=mediamtx-webcam` in the `.env`
2. Run: `docker compose up -d`
3. Run the script:

```bash
./scripts/start_webcam.sh              # device 0, publishes to tenda_cp7_main
./scripts/start_webcam.sh 1            # alternate device index
./scripts/start_webcam.sh 0 my_stream  # custom stream path
```

> **Important:** The script runs on your **host Mac** and publishes to `localhost:8554` (the port-mapped MediaMTX container).

### 2. Configure MediaMTX

Four preset configurations live in `configs/`:

| Config file | `MEDIAMTX_CONFIG` value | Use case |
|-------------|------------------------|----------|
| `mediamtx-mock.yml` | `mediamtx-mock` | Mock RTSP stream from video |
| `mediamtx-tenda-mac.yml` | `mediamtx-tenda-mac` (default) | Tenda CP7 via USB-Ethernet |
| `mediamtx-tenda-router.yml` | `mediamtx-tenda-router` | Tenda CP7 over Wi-Fi |
| `mediamtx-webcam.yml` | `mediamtx-webcam` | Local webcam via `start_webcam.sh` |

Set the `MEDIAMTX_CONFIG` variable in your `.env` to pick a config, for example:

```bash
MEDIAMTX_CONFIG=mediamtx-tenda-mac
```

> Each config file only overrides non-default values.
> Full reference: <https://github.com/bluenviron/mediamtx/blob/main/mediamtx.yml>

### 3. Run

All commands use `make`. The stack is split into compose layers:

| File | Variable | Contents |
|------|----------|----------|
| `compose.infra.yaml` | `COMPOSE_INFRA` | RabbitMQ, Qdrant, Gateway |
| `compose.yaml` | `COMPOSE_BASE` | MediaMTX, Inference, Recognition, Catalog, Recommendation, UI, Version Manager |
| `compose.mock.yaml` | `COMPOSE_MOCK` | MediaMTX override (pre-recorded video) |
| `compose.gpu.yaml` | `COMPOSE_GPU` | GPU resource reservation |

#### CPU Profiles

```bash
make mock           # Mock RTSP stream (pre-recorded video)
make tenda-mac      # Tenda camera via USB-Ethernet (macOS)
make tenda-router   # Tenda camera via Wi-Fi router
make webcam         # Local webcam + auto-stream
```

#### GPU Profiles

```bash
make mock-gpu           # Mock RTSP stream + GPU
make tenda-mac-gpu      # Tenda camera (macOS) + GPU
make tenda-router-gpu   # Tenda camera (router) + GPU
make webcam-gpu         # Local webcam + GPU
```

> **Note:** GPU mode requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

#### Submodule Microservices

```bash
make up-subs        # Start all submodule microservices
make down-subs      # Stop all submodule microservices
```

#### Utilities

```bash
make logs           # Tail logs for all services
make pull           # Pull latest images
make restart        # Restart app services only (infrastructure stays up)
make down           # Stop app services only
make down-all       # Stop all containers including infrastructure
```

#### Git

```bash
make reset          # Hard-reset to origin/main
make submodules     # Update and pull latest submodules
```

### 4. Verify

| Service | URL |
|---------|-----|
| RabbitMQ Management | <http://localhost:15672> |
| Qdrant Dashboard | <http://localhost:6333/dashboard> |
| MediaMTX API | <http://localhost:9997/v3/paths/list> |
| Version Manager API | <http://localhost:8000/docs> |
| Gateway API | <http://localhost:8001/docs> |
| Catalog API | <http://localhost:8003/docs> |
| Recommendation API | <http://localhost:8002/docs> |
| CogniBrew UI | <http://localhost:3000> |