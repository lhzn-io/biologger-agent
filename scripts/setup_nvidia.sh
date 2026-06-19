#!/bin/bash
# ==============================================================================
# Biologger Agent Stack Setup Script - NVIDIA CUDA Workstation / Server
# ==============================================================================
set -euo pipefail

# Ensure standard binary locations are in PATH
export PATH="$PATH:/usr/local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0;37m'

echo -e "${CYAN}=== Bootstrapping Biologger Agent Stack for NVIDIA/CUDA ===${NC}"

# 1. Verify Docker Engine
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker daemon is not running. Please start Docker service.${NC}"
    exit 1
fi
echo -e "${GREEN}[✔] Docker daemon is running${NC}"

# 2. Verify nvidia-smi & nvidia runtime
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}Warning: nvidia-smi is not found. GPU acceleration might fail.${NC}"
fi

if ! docker info | grep -q "Runtimes:.*nvidia"; then
    echo -e "${RED}Warning: 'nvidia' container runtime not registered in Docker. GPU serving will fail.${NC}"
    echo -e "${CYAN}Please install nvidia-container-toolkit and restart docker.${NC}"
fi

# 3. Locate and Build ZeroClaw image
UPLIFT_ROOT=""
PATHS=("/home/lhzn/Projects/lhzn-io/uplift" "/Users/lhzn/Projects/lhzn-io/uplift" "./uplift")
for p in "${PATHS[@]}"; do
    if [ -d "$p" ]; then
        UPLIFT_ROOT="$p"
        break
    fi
done

if [ -z "$UPLIFT_ROOT" ]; then
    echo -e "${RED}Error: Core uplift repo not found in standard paths.${NC}"
    echo -e "${CYAN}Please specify the path or run: git clone git@github.com:lhzn-io/uplift.git <path>${NC}"
    exit 1
fi

echo -e "${CYAN}Found uplift repo at $UPLIFT_ROOT${NC}"
if docker image inspect zeroclaw:latest >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] ZeroClaw image already exists. Skipping build.${NC}"
else
    echo -e "${CYAN}Building ZeroClaw container image...${NC}"
    docker build -t zeroclaw:latest "$UPLIFT_ROOT/stack/zeroclaw"
    echo -e "${GREEN}[✔] ZeroClaw image built successfully${NC}"
fi

# 4. Handle Environment Configuration
if [ ! -f .env ]; then
    echo -e "${CYAN}Creating local .env from template...${NC}"
    cp .env.template .env
    echo -e "${RED}Warning: Created .env. Please open .env and add your HF_TOKEN!${NC}"
else
    echo -e "${GREEN}[✔] Local .env file exists${NC}"
fi

# 5. Initialize Local Directories and copy Skills Registry
echo -e "${CYAN}Initializing workspaces and copying skills...${NC}"
mkdir -p ./workspace/operator/skills
mkdir -p ./workspace/admin/skills
mkdir -p ./config/.zeroclaw/operator
mkdir -p ./config/.zeroclaw/admin

# Copy custom operator and admin skills from git-tracked configs/skills
if [ -d "./configs/skills/operator" ]; then
    cp -r ./configs/skills/operator/* ./workspace/operator/skills/
fi
if [ -d "./configs/skills/admin" ]; then
    cp -r ./configs/skills/admin/* ./workspace/admin/skills/
fi

# Touch learned facts logs if not existing
touch ./config/.zeroclaw/operator/learned_facts.md
touch ./config/.zeroclaw/admin/learned_facts.md

# 6. Boot container stack with NVIDIA overrides
echo -e "${CYAN}Starting docker containers with NVIDIA GPU overrides...${NC}"
docker compose -f docker-compose.yml -f docker-compose.nvidia.yml up -d

echo -e "${GREEN}=== Bootstrapping Completed Successfully ===${NC}"
echo -e "${CYAN}Operator Gateway running at http://localhost:42617${NC}"
echo -e "${CYAN}Admin Gateway running at http://localhost:42618${NC}"
echo -e "${CYAN}vLLM Model Server running at http://localhost:8000/v1${NC}"
