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

.PHONY: submodules
submodules: ## Update and pull the latest changes for all submodules
	git submodule update --init --recursive --remote

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
webcam: ## Run with local webcam + auto-stream
	MEDIAMTX_CONFIG=mediamtx-webcam $(COMPOSE) $(COMPOSE_BASE) up -d
	./scripts/start_webcam.sh

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
webcam-gpu: ## Run with local webcam + GPU + auto-stream
	MEDIAMTX_CONFIG=mediamtx-webcam $(COMPOSE) $(COMPOSE_BASE) $(COMPOSE_GPU) up -d
	./scripts/start_webcam.sh

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
.PHONY: logs
logs: ## Tail logs for all services
	$(COMPOSE) $(COMPOSE_BASE) logs -f

.PHONY: start-subs
start-subs: ## Start all submodule microservices
	$(COMPOSE) -f services/usermanagement/docker-compose.yaml up -d
	$(COMPOSE) -f services/member/docker-compose.yaml up -d
	$(COMPOSE) -f services/feedback/docker-compose.yaml up -d
	$(COMPOSE) -f services/notification/docker-compose.yaml up -d

.PHONY: stop-subs
stop-subs: ## Stop all submodule microservices
	$(COMPOSE) -f services/usermanagement/docker-compose.yaml down
	$(COMPOSE) -f services/member/docker-compose.yaml down
	$(COMPOSE) -f services/feedback/docker-compose.yaml down
	$(COMPOSE) -f services/notification/docker-compose.yaml down

.PHONY: pull
pull: ## Pull latest images
	$(COMPOSE) $(COMPOSE_BASE) pull

.PHONY: down
down: ## Stop and remove all containers
	$(COMPOSE) $(COMPOSE_BASE) down

.PHONY: down-v
down-v: ## Stop and remove all containers + volumes
	$(COMPOSE) $(COMPOSE_BASE) down -v
