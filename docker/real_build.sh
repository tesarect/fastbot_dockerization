#!/bin/bash
# =============================================================================
# real_build.sh  —  FastBot Real Robot Image Builder
#
# Run from ros2_ws/src/ (build context — has all packages at root level)
#
# Usage:
#   ./docker/real/real_build.sh              # build all real robot images
#   ./docker/real/real_build.sh robot        # build only robot drivers image
#   ./docker/real/real_build.sh slam         # build only slam image
#   ./docker/real/real_build.sh robot slam   # build multiple
# =============================================================================

set -e

# ── Config ────────────────────────────────────────────────────────────────────
REPO="${DOCKERHUB_USER:-your_username}-cp22"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"  # ros2_ws/src/ (docker/ lives inside src/)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[build]${NC} $*"; }
success() { echo -e "${GREEN}[done] ${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn] ${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*"; exit 1; }

# ── Architecture check ────────────────────────────────────────────────────────
check_arch() {
    local arch=$(uname -m)
    if [ "$arch" != "aarch64" ] && [ "$arch" != "armv7l" ]; then
        warn "You are building on ${arch} (not ARM)."
        warn "Real robot images should be built ON the Raspberry Pi (aarch64)."
        warn "Images built here won't run on the Pi."
        echo ""
        read -rp "Continue anyway? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    else
        log "Architecture: ${arch} ✅"
    fi
}

# ── Verify required packages exist ───────────────────────────────────────────
check_packages() {
    local target=$1
    local missing=()

    case "$target" in
        robot)
            for pkg in fastbot_bringup fastbot_description \
                       serial_motor serial_motor_msgs Lslidar_ROS2_driver; do
                [ ! -d "${PROJECT_ROOT}/${pkg}" ] && missing+=("$pkg")
            done
            ;;
        slam)
            for pkg in fastbot_slam; do
                [ ! -d "${PROJECT_ROOT}/${pkg}" ] && missing+=("$pkg")
            done
            ;;
    esac

    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing packages for '${target}': ${missing[*]}"
        warn "Expected at: ${PROJECT_ROOT}/"
        echo ""
        read -rp "Continue anyway? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi
}

# ── Build a single image ──────────────────────────────────────────────────────
build_image() {
    local name=$1
    local tag=$2
    local dockerfile=$3

    echo ""
    log "Building ${tag} ..."
    echo "──────────────────────────────────────────────"

    local start=$(date +%s)

    docker build \
        -f "${dockerfile}" \
        -t "${tag}" \
        "${PROJECT_ROOT}"

    local elapsed=$(( $(date +%s) - start ))
    success "${tag} built in ${elapsed}s"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    local targets=("$@")
    [ ${#targets[@]} -eq 0 ] && targets=("robot" "slam")

    echo ""
    echo "=============================================="
    echo "  FastBot Real Robot Build"
    echo "  Repo    : ${REPO}"
    echo "  Targets : ${targets[*]}"
    echo "  Context : ${PROJECT_ROOT}"
    echo "  Arch    : $(uname -m)"
    echo "=============================================="

    # Validate targets
    for t in "${targets[@]}"; do
        case "$t" in
            robot|slam) ;;
            *) error "Unknown target '${t}'. Valid: robot | slam" ;;
        esac
    done

    check_arch

    local overall_start=$(date +%s)

    for target in "${targets[@]}"; do
        check_packages "$target"
        case "$target" in
            robot)
                build_image "robot" \
                    "${REPO}:fastbot-ros2-real" \
                    "${SCRIPT_DIR}/real/Dockerfile.real"
                ;;
            slam)
                build_image "slam" \
                    "${REPO}:fastbot-ros2-slam-real" \
                    "${SCRIPT_DIR}/real/Dockerfile.slam-real"
                ;;
        esac
    done

    local total=$(( $(date +%s) - overall_start ))

    echo ""
    echo "=============================================="
    success "All done in ${total}s"
    echo ""
    echo "  Images built:"
    docker images | grep "${REPO}" | grep -E "real" | \
        awk '{printf "  %-45s %s\n", $1":"$2, $7" "$8}'
    echo ""
    echo "  Push to Docker Hub:"
    for target in "${targets[@]}"; do
        case "$target" in
            robot) echo "    docker push ${REPO}:fastbot-ros2-real" ;;
            slam)  echo "    docker push ${REPO}:fastbot-ros2-slam-real" ;;
        esac
    done
    echo ""
    echo "  Start the robot:"
    echo "    cd docker/real"
    echo "    docker-compose up -d robot"
    echo "=============================================="
}

main "$@"
