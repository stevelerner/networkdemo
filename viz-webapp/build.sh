#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}=================================================="
echo "Network Visualization Webapp - Build Script"
echo -e "==================================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}WARNING: Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker is running${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check required files exist
echo -e "${CYAN}Checking required files...${NC}"
if [ ! -f "$SCRIPT_DIR/Dockerfile" ]; then
    echo "ERROR: Dockerfile not found"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/app.py" ]; then
    echo "ERROR: app.py not found"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/templates" ]; then
    echo "ERROR: templates/ directory not found"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/static" ]; then
    echo "ERROR: static/ directory not found"
    exit 1
fi

echo -e "${GREEN}All required files present${NC}"
echo ""

# Build the image
echo -e "${CYAN}Building viz-webapp Docker image...${NC}"
echo ""

docker build -t networkdemo_viz:latest "$SCRIPT_DIR"

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================================="
    echo "Build successful!"
    echo -e "==================================================${NC}"
    echo ""
    echo "Image built: networkdemo_viz:latest"
    echo ""
    echo "To run standalone:"
    echo "  docker run -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock networkdemo_viz:latest"
    echo ""
    echo "Or use docker compose from the parent directory:"
    echo "  cd .. && docker compose up -d viz"
    echo ""
else
    echo ""
    echo -e "${YELLOW}=================================================="
    echo "Build failed with exit code: $BUILD_EXIT_CODE"
    echo -e "==================================================${NC}"
    exit $BUILD_EXIT_CODE
fi

