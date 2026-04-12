# -----------------------------------------------------------------------------
# Cognibrew Edge – Makefile
# -----------------------------------------------------------------------------
COMPOSE        := docker compose
COMPOSE_BASE   := -f compose.yaml
COMPOSE_MOCK   := -f compose.yaml -f compose.mock.yaml
COMPOSE_GPU    := -f compose.gpu.yaml

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
.PHONY: reset
reset: ## Hard-reset to origin/main
	git fetch origin
	git reset --hard origin/main

# -----------------------------------------------------------------------------
# Run profiles (CPU)
# -----------------------------------------------------------------------------
.PHONY: mock
mock: ## Run with mock RTSP stream (pre-recorded video)
	MEDIAMTX_CONFIG=mediamtx-mock $(COMPOSE) $(COMPOSE_MOCK) up -d

.PHONY: tenda-mac
tenda-mac: ## Run with Tenda camera (macOS USB-Connected)
	MEDIAMTX_CONFIG=mediamtx-tenda-mac $(COMPOSE) $(COMPOSE_BASE) up -d

.PHONY: tenda-router
tenda-router: ## Run with Tenda camera (via wifi-router)
	MEDIAMTX_CONFIG=mediamtx-tenda-router $(COMPOSE) $(COMPOSE_BASE) up -d

.PHONY: webcam
webcam: ## Run with local webcam
	MEDIAMTX_CONFIG=mediamtx-webcam $(COMPOSE) $(COMPOSE_BASE) up -d

# -----------------------------------------------------------------------------
# Run profiles (GPU)
# -----------------------------------------------------------------------------
.PHONY: mock-gpu
mock-gpu: ## Run with mock RTSP stream + GPU
	MEDIAMTX_CONFIG=mediamtx-mock $(COMPOSE) $(COMPOSE_MOCK) $(COMPOSE_GPU) up -d

.PHONY: tenda-mac-gpu
tenda-mac-gpu: ## Run with Tenda camera (macOS USB-Connected) + GPU
	MEDIAMTX_CONFIG=mediamtx-tenda-mac $(COMPOSE) $(COMPOSE_BASE) $(COMPOSE_GPU) up -d

.PHONY: tenda-router-gpu
tenda-router-gpu: ## Run with Tenda camera (via router) + GPU
	MEDIAMTX_CONFIG=mediamtx-tenda-router $(COMPOSE) $(COMPOSE_BASE) $(COMPOSE_GPU) up -d

.PHONY: webcam-gpu
webcam-gpu: ## Run with local webcam + GPU
	MEDIAMTX_CONFIG=mediamtx-webcam $(COMPOSE) $(COMPOSE_BASE) $(COMPOSE_GPU) up -d

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
.PHONY: logs
logs: ## Tail logs for all services
	$(COMPOSE) $(COMPOSE_BASE) logs -f

.PHONY: pull
pull: ## Pull latest images
	$(COMPOSE) $(COMPOSE_BASE) pull

.PHONY: down
down: ## Stop and remove all containers
	$(COMPOSE) $(COMPOSE_BASE) down

.PHONY: down-v
down-v: ## Stop and remove all containers + volumes
	$(COMPOSE) $(COMPOSE_BASE) down -v
