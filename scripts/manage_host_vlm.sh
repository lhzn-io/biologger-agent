#!/bin/bash
# ==============================================================================
# Native VLM Host Manager Wrapper
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0;37m'

VLM_EXPERT_DIR="/Users/lhzn/Projects/whoi-mpg/biologger-expert"
VLM_MANAGE_SCRIPT="$VLM_EXPERT_DIR/scripts/manage_mlx_vlm.sh"

ACTION=${1:-status}

if [ ! -f "$VLM_MANAGE_SCRIPT" ]; then
    echo -e "${RED}Error: Host VLM manager script not found at $VLM_MANAGE_SCRIPT${NC}"
    echo -e "${RED}Please verify that 'whoi-mpg/biologger-expert' is cloned at $VLM_EXPERT_DIR${NC}"
    exit 1
fi

echo -e "${CYAN}Delegating to: $VLM_MANAGE_SCRIPT $ACTION${NC}"
bash "$VLM_MANAGE_SCRIPT" "$ACTION"
