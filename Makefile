# -----------------------------------------------------------------------------
# Cognibrew Edge – Makefile
# -----------------------------------------------------------------------------
COMPOSE        := docker compose
COMPOSE_INFRA  := -f compose.infra.yaml
COMPOSE_BASE   := -f compose.yaml
COMPOSE_MOCK   := -f compose.mock.yaml
COMPOSE_GPU    := -f compose.gpu.yaml
BASE_SERVICES := mediamtx inference-server recognition-service version-manager \
				catalog recommendation ui

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
.PHONY: reset
reset: ## Hard-reset to origin/main
	git fetch origin
	git reset --hard origin/main

.PHONY: submodules
submodules: ## Update and pull the latest changes for all submodules
	git submodule update --init --recursive --remote

# -----------------------------------------------------------------------------
# Run profiles (CPU)
# -----------------------------------------------------------------------------
.PHONY: mock
mock: ## Run with mock RTSP stream (pre-recorded video)
	MEDIAMTX_CONFIG=mediamtx-mock \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		$(COMPOSE_MOCK) \
		up -d

.PHONY: tenda-mac
tenda-mac: ## Run with Tenda camera (macOS USB-Connected)
	MEDIAMTX_CONFIG=mediamtx-tenda-mac \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		up -d

.PHONY: tenda-router
tenda-router: ## Run with Tenda camera (via wifi-router)
	MEDIAMTX_CONFIG=mediamtx-tenda-router \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		up -d

.PHONY: webcam
webcam: ## Run with local webcam + auto-stream
	MEDIAMTX_CONFIG=mediamtx-webcam \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		up -d
	./scripts/start_webcam.sh

# -----------------------------------------------------------------------------
# Run profiles (GPU)
# -----------------------------------------------------------------------------
.PHONY: mock-gpu
mock-gpu: ## Run with mock RTSP stream + GPU
	MEDIAMTX_CONFIG=mediamtx-mock \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		$(COMPOSE_MOCK) \
		$(COMPOSE_GPU) \
		up -d

.PHONY: tenda-mac-gpu
tenda-mac-gpu: ## Run with Tenda camera (macOS USB-Connected) + GPU
	MEDIAMTX_CONFIG=mediamtx-tenda-mac \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		$(COMPOSE_GPU) \
		up -d

.PHONY: tenda-router-gpu
tenda-router-gpu: ## Run with Tenda camera (via router) + GPU
	MEDIAMTX_CONFIG=mediamtx-tenda-router \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		$(COMPOSE_GPU) \
		up -d

.PHONY: webcam-gpu
webcam-gpu: ## Run with local webcam + GPU + auto-stream
	MEDIAMTX_CONFIG=mediamtx-webcam \
		$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		$(COMPOSE_GPU) \
		up -d
	./scripts/start_webcam.sh


# -----------------------------------------------------------------------------
# Submodules
# -----------------------------------------------------------------------------
.PHONY: up-subs
up-subs: ## Start all submodule microservices
	$(COMPOSE) -f services/usermanagement/docker-compose.yaml up -d
	$(COMPOSE) -f services/member/docker-compose.yaml up -d
	$(COMPOSE) -f services/feedback/docker-compose.yaml up -d
	$(COMPOSE) -f services/notification/docker-compose.yaml up -d

.PHONY: down-subs
down-subs: ## Stop all submodule microservices
	$(COMPOSE) -f services/usermanagement/docker-compose.yaml down
	$(COMPOSE) -f services/member/docker-compose.yaml down
	$(COMPOSE) -f services/feedback/docker-compose.yaml down
	$(COMPOSE) -f services/notification/docker-compose.yaml down

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
.PHONY: logs
logs: ## Tail logs for all services
	$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		logs -f

.PHONY: pull
pull: ## Pull latest images
	$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		pull

.PHONY: down
down: ## Stop app services only (infrastructure stays up)
	$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		rm -sf $(BASE_SERVICES)

.PHONY: restart
restart: ## Restart app services only (infrastructure stays up)
	$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		rm -sf $(BASE_SERVICES)
	$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		up -d

.PHONY: down-all
down-all: ## Stop and remove all containers including infrastructure
	$(COMPOSE) \
		$(COMPOSE_INFRA) \
		$(COMPOSE_BASE) \
		down
