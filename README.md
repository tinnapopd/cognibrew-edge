# Cognibrew Edge (Example Repository)

Edge deployment stack for the Cognibrew face-recognition platform.

## Services

| Service | Image | Description |
|---------|-------|-------------|
| **mediamtx** | `bluenviron/mediamtx:1.17.0` | RTSP media proxy |
| **rabbitmq** | `rabbitmq:4.2.5-management-alpine` | Message broker (AMQP) |
| **qdrant** | `qdrant/qdrant:v1.17` | Vector database (gRPC on 6334) |
| **inference-server** | `teetinnapop/actions:cognibrew-inference-server-latest` | RTSP stream → face embeddings → RabbitMQ |
| **recognition-service** | `teetinnapop/actions:cognibrew-recognition-service-latest` | Embedding matching via Qdrant |
| **version-manager** | `teetinnapop/actions:cognibrew-version-manager-latest` | Config management API (port 8000) |

## Quick Start

### 1. Find Your Camera IP

Use the discovery script to locate ONVIF cameras on your network:

```bash
pip install onvif-zeep WSDiscovery
python scripts/discover_rtsp.py --auto
```

This will output the camera IP and RTSP stream URIs. You can also scan by subnet:

```bash
python scripts/discover_rtsp.py --scan 192.168.1.0
```

### 2. Configure MediaMTX

Edit `services/mediamtx/mediamtx.yml` to set the camera credentials and RTSP source path:

```yaml
# Authentication
authInternalUsers:
  - user: <your-mediamtx-user>
    pass: <your-mediamtx-password>
    ...

# Path settings
paths:
  my_camera:
    source: rtsp://<cam-user>:<cam-password>@<camera-ip>:554/<path>
    sourceOnDemand: true
```

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` to match the values in `.env.example`. Key variables:

| Group | Variable | Default |
|-------|----------|---------|
| Logging | `LOG_LEVEL` | `INFO` |
| RabbitMQ | `RABBITMQ_USERNAME` / `RABBITMQ_PASSWORD` | `guest` / `guest` |
| Inference | `STREAM_SKIP_FRAME` | `5` |
| Inference | `STREAM_APPLY_DIFF` / `STREAM_DIFF_THRESHOLD` | `true` / `5.0` |
| Inference | `MODEL_FRAMEWORK` / `MODEL_NAME` | `insightface` / `buffalo_sc` |
| Recognition | `MODEL_SIMILARITY_THRESHOLD` | `0.65` |
| Recognition | `QDRANT_COLLECTION_NAME` / `QDRANT_EMBEDDING_DIM` | `face_embeddings` / `512` |
| Version Mgr | `DOCKER_TARGET_LABEL` | `cognibrew.service=recognition` |

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
| RabbitMQ Management | http://localhost:15672 |
| MediaMTX API | http://localhost:9997/v3/paths/list |
| Version Manager API | http://localhost:8000/docs |

### 6. Stop

```bash
docker compose down          # keep volumes
docker compose down -v       # remove volumes
```
