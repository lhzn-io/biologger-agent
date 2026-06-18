#!/bin/bash
# ==============================================================================
# Biologger Agent Stack Setup Script - macOS / Apple Silicon
# ==============================================================================
set -euo pipefail

# Ensure standard macOS GUI app binary locations are in PATH (for OrbStack/Docker under non-interactive SSH)
export PATH="$PATH:/usr/local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0;37m'

echo -e "${CYAN}=== Bootstrapping Biologger Agent Stack for macOS ===${NC}"

# 1. Verify Docker Engine
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker daemon is not running. Please start OrbStack or Docker Desktop.${NC}"
    exit 1
fi
echo -e "${GREEN}[✔] Docker daemon is running${NC}"

# 2. Build ZeroClaw image from local uplift clone
UPLIFT_ROOT="/Users/lhzn/Projects/lhzn-io/uplift"
if [ ! -d "$UPLIFT_ROOT" ]; then
    echo -e "${RED}Error: Core uplift repo not found at $UPLIFT_ROOT.${NC}"
    echo -e "${CYAN}Please run: git clone git@github.com:lhzn-io/uplift.git $UPLIFT_ROOT${NC}"
    exit 1
fi

echo -e "${CYAN}Building ZeroClaw container image from $UPLIFT_ROOT...${NC}"
docker build -t zeroclaw:latest "$UPLIFT_ROOT/stack/zeroclaw"
echo -e "${GREEN}[✔] ZeroClaw image built successfully${NC}"

# 3. Handle Environment Configuration
if [ ! -f .env ]; then
    echo -e "${CYAN}Creating local .env from template...${NC}"
    cp .env.template .env
    echo -e "${RED}Warning: Created .env. Please open .env and add your HF_TOKEN!${NC}"
else
    echo -e "${GREEN}[✔] Local .env file exists${NC}"
fi

# 4. Initialize Local Directories
mkdir -p ./workspace
mkdir -p ./config/.zeroclaw

# 5. Boot container stack
echo -e "${CYAN}Starting docker containers...${NC}"
docker compose -f docker-compose.yml up -d

echo -e "${GREEN}=== Bootstrapping Completed Successfully ===${NC}"
echo -e "${CYAN}ZeroClaw Gateway running at http://localhost:42617${NC}"
