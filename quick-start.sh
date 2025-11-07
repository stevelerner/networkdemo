#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}=================================================="
echo "🚀 Network Demo - Quick Start"
echo -e "==================================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Check if certificates exist
if [ ! -f "./nginx/certs/app.demo.local.crt" ]; then
    echo -e "${YELLOW}📜 Generating SSL certificates...${NC}"
    chmod +x generate-certs.sh
    ./generate-certs.sh
    echo ""
else
    echo -e "${GREEN}✓ SSL certificates already exist${NC}"
    echo ""
fi

# Build and start containers
echo -e "${CYAN}🔨 Building Docker images...${NC}"
docker compose build --quiet

echo ""
echo -e "${CYAN}🚀 Starting containers...${NC}"
docker compose up -d

echo ""
echo -e "${GREEN}✅ All containers started!${NC}"
echo ""

# Wait a few seconds for services to initialize
echo -e "${CYAN}⏳ Waiting for services to initialize...${NC}"
sleep 5

# Show status
echo ""
echo -e "${CYAN}📊 Container Status:${NC}"
docker compose ps

echo ""
echo -e "${GREEN}=================================================="
echo "✅ Setup Complete!"
echo -e "==================================================${NC}"
echo ""
echo "Try these commands:"
echo ""
echo -e "  ${CYAN}make demo-dns${NC}       - Test DNS resolution"
echo -e "  ${CYAN}make demo-https${NC}     - Test HTTPS connectivity"
echo -e "  ${CYAN}make demo-routing${NC}   - Test inter-VLAN routing"
echo -e "  ${CYAN}make demo-all${NC}       - Run all demos"
echo -e "  ${CYAN}make help${NC}           - See all available commands"
echo ""
echo -e "  ${CYAN}make shell-client10${NC} - Open shell in VLAN10 client"
echo -e "  ${CYAN}make monitor${NC}        - Watch live network traffic"
echo ""
echo -e "${GREEN}Happy networking! 🎉${NC}"

