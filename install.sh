#!/bin/bash

# Video Stream Detector - Ubuntu Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/video-stream-detector/main/install.sh | bash

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   🎬 Video Stream Detector - Installation Script          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Running as root. Consider running as regular user.${NC}"
fi

# Update system
echo -e "${GREEN}[1/6] Updating system packages...${NC}"
sudo apt update -y

# Install dependencies
echo -e "${GREEN}[2/6] Installing system dependencies...${NC}"
sudo apt install -y curl git

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${GREEN}[3/6] Installing Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}[3/6] Node.js already installed: ${NODE_VERSION}${NC}"
fi

# Install Playwright system dependencies
echo -e "${GREEN}[4/6] Installing Playwright browser dependencies...${NC}"
sudo npx playwright install-deps chromium

# Clone repository (if not already in the directory)
INSTALL_DIR="$HOME/video-stream-detector"
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}[5/6] Cloning repository...${NC}"
    git clone https://github.com/YOUR_USERNAME/video-stream-detector.git "$INSTALL_DIR"
else
    echo -e "${GREEN}[5/6] Directory exists, pulling latest...${NC}"
    cd "$INSTALL_DIR" && git pull
fi

# Install npm dependencies
echo -e "${GREEN}[6/6] Installing npm dependencies and Playwright...${NC}"
cd "$INSTALL_DIR"
npm install
npx playwright install chromium

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Installation Complete!                                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "To start the server:"
echo "  cd $INSTALL_DIR"
echo "  npm start"
echo ""
echo "Or run with PM2 (recommended for production):"
echo "  sudo npm install -g pm2"
echo "  pm2 start server.js --name video-detector"
echo "  pm2 save"
echo "  pm2 startup"
echo ""
echo "Server will be available at: http://localhost:3333"
echo ""
