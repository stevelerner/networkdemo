#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}======================================${NC}"
echo -e "${RED}FORCE CLEANUP - Removing all traces${NC}"
echo -e "${RED}======================================${NC}"
echo ""

# Stop and remove all containers
echo -e "${YELLOW}Stopping containers...${NC}"
docker compose down -v --remove-orphans 2>/dev/null || true

# Remove any containers with our names
echo -e "${YELLOW}Removing any stray containers...${NC}"
docker rm -f router coredns dnsmasq nginx-app client10 client20 monitor wan-host 2>/dev/null || true

# Remove networks
echo -e "${YELLOW}Removing networks...${NC}"
docker network rm networkdemo_vlan10 networkdemo_vlan20 networkdemo_wan 2>/dev/null || true
docker network rm networkingdemo_vlan10 networkingdemo_vlan20 networkingdemo_wan 2>/dev/null || true
docker network rm vlan10 vlan20 wan 2>/dev/null || true

# Prune all unused networks
echo -e "${YELLOW}Pruning unused networks...${NC}"
docker network prune -f

# Remove images (optional)
echo -e "${YELLOW}Removing built images...${NC}"
docker rmi networkdemo-router networkdemo-clients networkingdemo-router networkingdemo-clients 2>/dev/null || true
docker rmi networkdemo_router networkdemo_clients networkingdemo_router networkingdemo_clients 2>/dev/null || true

# Remove volumes
echo -e "${YELLOW}Removing volumes...${NC}"
docker volume prune -f

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✅ Force cleanup complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "You can now run: make certs && make up"

