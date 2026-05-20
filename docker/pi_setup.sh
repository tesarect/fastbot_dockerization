#!/bin/bash
# =============================================================================
# pi_setup.sh  —  FastBot Raspberry Pi Host Setup
#
# Run ONCE on the Raspberry Pi before any Docker work.
# Sets up: udev rules, camera driver, groups, Docker.
#
# Usage:
#   chmod +x pi_setup.sh
#   ./pi_setup.sh              # service runs as 'fastbot'
#   ./pi_setup.sh <username>   # service runs as given user
#
# After running: REBOOT the Pi for all changes to take effect.
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[setup]${NC} $*"; }
success() { echo -e "${GREEN}[done] ${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn] ${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*"; exit 1; }

ROBOT_USER="${1:-fastbot}"

echo ""
echo "=============================================="
echo "  FastBot Raspberry Pi Host Setup"
echo "  Run once before Docker setup"
echo "  Service user: ${ROBOT_USER}"
echo "=============================================="
echo ""

# ── Check running on Pi ───────────────────────────────────────────────────────
if [ "$(uname -m)" != "aarch64" ]; then
    warn "Not running on ARM64. This script is for Raspberry Pi only."
    read -rp "Continue anyway? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi

# ── 1. System update ──────────────────────────────────────────────────────────
log "Updating system packages..."
sudo apt-get update -q
sudo apt-get upgrade -y -q
success "System updated"

# ── 2. Install dependencies ───────────────────────────────────────────────────
log "Installing required system packages..."
sudo apt-get install -y --no-install-recommends \
    udev \
    v4l-utils \
    curl \
    git \
    screen
success "System packages installed"

# ── 3. udev rule — LSlidar N10 ────────────────────────────────────────────────
log "Creating udev rule for LSlidar N10 → /dev/lslidar ..."
echo ""
warn "You need the LSlidar's USB Vendor and Product ID."
warn "Connect the LSlidar and run: lsusb"
warn "Look for a line like: Bus 001 Device 003: ID 10c4:ea60 ..."
echo ""
read -rp "  Enter Vendor ID  (default: 10c4): " LIDAR_VENDOR
read -rp "  Enter Product ID (default: ea60): " LIDAR_PRODUCT
LIDAR_VENDOR=${LIDAR_VENDOR:-10c4}
LIDAR_PRODUCT=${LIDAR_PRODUCT:-ea60}

sudo tee /etc/udev/rules.d/99-lslidar.rules > /dev/null << UDEV
SUBSYSTEM=="tty", ATTRS{idVendor}=="${LIDAR_VENDOR}", ATTRS{idProduct}=="${LIDAR_PRODUCT}", SYMLINK+="lslidar"
UDEV
success "LSlidar udev rule created: /dev/lslidar"

# ── 4. udev rule — Arduino Nano ───────────────────────────────────────────────
log "Creating udev rule for Arduino Nano → /dev/arduino_nano ..."
echo ""
warn "You need the Arduino's USB Vendor and Product ID."
warn "Connect the Arduino and run: lsusb"
warn "Common IDs: 1a86:7523 (CH340) or 2341:0043 (genuine Nano)"
echo ""
read -rp "  Enter Vendor ID  (default: 1a86): " ARDUINO_VENDOR
read -rp "  Enter Product ID (default: 7523): " ARDUINO_PRODUCT
ARDUINO_VENDOR=${ARDUINO_VENDOR:-1a86}
ARDUINO_PRODUCT=${ARDUINO_PRODUCT:-7523}

sudo tee /etc/udev/rules.d/99-arduino.rules > /dev/null << UDEV
SUBSYSTEM=="tty", ATTRS{idVendor}=="${ARDUINO_VENDOR}", ATTRS{idProduct}=="${ARDUINO_PRODUCT}", SYMLINK+="arduino_nano"
UDEV
success "Arduino udev rule created: /dev/arduino_nano"

# ── 5. Reload udev rules ──────────────────────────────────────────────────────
log "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger
success "udev rules reloaded"

# ── 6. Camera — legacy driver setup ──────────────────────────────────────────
log "Configuring Raspberry Pi camera (legacy bm2835 mmal driver)..."
CONFIG_FILE="/boot/firmware/config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    warn "$CONFIG_FILE not found — skipping camera setup"
    warn "You may need to configure it manually"
else
    # Disable camera_autodetect
    if grep -q "^camera_autodetect" "$CONFIG_FILE"; then
        sudo sed -i 's/^camera_autodetect=.*/camera_autodetect=0/' "$CONFIG_FILE"
    else
        echo "camera_autodetect=0" | sudo tee -a "$CONFIG_FILE" > /dev/null
    fi

    # Add start_x=1 if not present
    if ! grep -q "^start_x=1" "$CONFIG_FILE"; then
        echo "start_x=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
    fi

    success "Camera configured in $CONFIG_FILE"
    warn "Camera changes require a REBOOT to take effect"
fi

# ── 7. Add user to required groups ───────────────────────────────────────────
log "Adding $USER to dialout and video groups..."
sudo usermod -aG dialout $USER
sudo usermod -aG video $USER
success "User added to groups (takes effect after reboot)"

# ── 8. Install Docker ─────────────────────────────────────────────────────────
log "Installing Docker..."
if command -v docker &> /dev/null; then
    success "Docker already installed: $(docker --version)"
else
    curl -fsSL https://get.docker.com | sh
    success "Docker installed"
fi

sudo usermod -aG docker $USER
sudo apt-get install -y docker-compose
success "docker-compose installed"

# ── 9. Start Docker service ───────────────────────────────────────────────────
log "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker
success "Docker service enabled and started"

# ── 10. Set DOCKERHUB_USER ───────────────────────────────────────────────────
echo ""
read -rp "Enter your Docker Hub username (for image tagging): " DOCKER_USER
if [ -n "$DOCKER_USER" ]; then
    echo "export DOCKERHUB_USER=\"${DOCKER_USER}\"" >> ~/.bashrc
    success "DOCKERHUB_USER set to: ${DOCKER_USER}"
fi

# ── 11. Install fastbot systemd service ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_SRC="${SCRIPT_DIR}/real/scripts/fastbot.service"

log "Installing fastbot systemd service..."

if [ ! -f "$SERVICE_SRC" ]; then
    warn "fastbot.service not found at ${SERVICE_SRC} — skipping"
else
    sed "s|User=fastbot|User=${ROBOT_USER}|g; s|/home/fastbot|/home/${ROBOT_USER}|g" \
        "$SERVICE_SRC" | sudo tee /etc/systemd/system/fastbot.service > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable fastbot.service
    sudo systemctl start fastbot.service
    success "fastbot.service installed, enabled, and started"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
success "Pi host setup complete!"
echo ""
echo "  Created:"
echo "    /etc/udev/rules.d/99-lslidar.rules"
echo "    /etc/udev/rules.d/99-arduino.rules"
echo "    /etc/systemd/system/fastbot.service"
echo ""
echo "  Configured:"
echo "    /boot/firmware/config.txt (camera)"
echo ""
echo "  Groups added:"
echo "    dialout, video, docker"
echo ""
echo "  ⚠️  REBOOT REQUIRED for all changes to take effect:"
echo "    sudo reboot"
echo ""
echo "  After reboot, verify devices:"
echo "    ls -la /dev/lslidar /dev/arduino_nano /dev/video0"
echo ""
echo "  Then build Docker images:"
echo "    cd ~/ros2_ws/src"
echo "    ./docker/real_build.sh"
echo "=============================================="
