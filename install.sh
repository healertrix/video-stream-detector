#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Video Stream Detector - One-Click Ubuntu Installation Script             ║
# ║                                                                           ║
# ║  Usage:                                                                   ║
# ║  curl -fsSL https://raw.githubusercontent.com/healertrix/video-stream-detector/main/install.sh | bash
# ║                                                                           ║
# ║  Or with sudo (if needed):                                                ║
# ║  curl -fsSL https://raw.githubusercontent.com/healertrix/video-stream-detector/main/install.sh | sudo bash
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/healertrix/video-stream-detector.git"
INSTALL_DIR="${INSTALL_DIR:-$HOME/video-stream-detector}"
PORT="${PORT:-3333}"

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   🎬 Video Stream Detector - Auto Installer               ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Detect if we need sudo
need_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "sudo"
    else
        echo ""
    fi
}

SUDO=$(need_sudo)

print_banner

# Step 1: System update
echo ""
log_info "Step 1/6: Updating system packages..."
$SUDO apt update -y > /dev/null 2>&1
log_step "System updated"

# Step 2: Install dependencies
log_info "Step 2/6: Installing dependencies (curl, git)..."
$SUDO apt install -y curl git > /dev/null 2>&1
log_step "Dependencies installed"

# Step 3: Install Node.js
log_info "Step 3/6: Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VER=$(node -v)
    NODE_MAJOR=$(echo $NODE_VER | cut -d'.' -f1 | tr -d 'v')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        log_step "Node.js $NODE_VER already installed"
    else
        log_warn "Node.js $NODE_VER is too old, upgrading..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash - > /dev/null 2>&1
        $SUDO apt install -y nodejs > /dev/null 2>&1
        log_step "Node.js upgraded to $(node -v)"
    fi
else
    log_info "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E bash - > /dev/null 2>&1
    $SUDO apt install -y nodejs > /dev/null 2>&1
    log_step "Node.js $(node -v) installed"
fi

# Step 4: Install Playwright system dependencies
log_info "Step 4/6: Installing Playwright browser dependencies..."
$SUDO npx playwright install-deps chromium > /dev/null 2>&1
log_step "Playwright dependencies installed"

# Step 5: Clone/Update repository
log_info "Step 5/6: Setting up project..."
if [ -d "$INSTALL_DIR" ]; then
    log_info "Directory exists, pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull > /dev/null 2>&1
    log_step "Repository updated"
else
    git clone "$REPO_URL" "$INSTALL_DIR" > /dev/null 2>&1
    cd "$INSTALL_DIR"
    log_step "Repository cloned to $INSTALL_DIR"
fi

# Step 6: Install npm packages and Playwright browser
log_info "Step 6/6: Installing npm packages and Playwright Chromium..."
npm install > /dev/null 2>&1
npx playwright install chromium > /dev/null 2>&1
log_step "All packages installed"

# Step 7: Setup PM2 (optional but recommended)
echo ""
log_info "Setting up PM2 for production..."
if ! command -v pm2 &> /dev/null; then
    $SUDO npm install -g pm2 > /dev/null 2>&1
    log_step "PM2 installed globally"
else
    log_step "PM2 already installed"
fi

# Stop existing instance if running
pm2 delete video-detector > /dev/null 2>&1 || true

# Start with PM2
cd "$INSTALL_DIR"
pm2 start server.js --name video-detector > /dev/null 2>&1
pm2 save > /dev/null 2>&1
log_step "Server started with PM2"

# Setup startup script
pm2 startup > /dev/null 2>&1 || true

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Print success message
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Installation Complete!                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "   ${CYAN}🌐 Web UI:${NC}     http://${SERVER_IP}:${PORT}"
echo -e "   ${CYAN}🔌 API:${NC}        http://${SERVER_IP}:${PORT}/api/detect?url=<embed_url>"
echo -e "   ${CYAN}📁 Install Dir:${NC} ${INSTALL_DIR}"
echo ""
echo -e "   ${YELLOW}Commands:${NC}"
echo -e "   • View logs:    ${BLUE}pm2 logs video-detector${NC}"
echo -e "   • Restart:      ${BLUE}pm2 restart video-detector${NC}"
echo -e "   • Stop:         ${BLUE}pm2 stop video-detector${NC}"
echo -e "   • Status:       ${BLUE}pm2 status${NC}"
echo ""
echo -e "   ${YELLOW}Firewall (if needed):${NC}"
echo -e "   ${BLUE}sudo ufw allow ${PORT}/tcp${NC}"
echo ""
