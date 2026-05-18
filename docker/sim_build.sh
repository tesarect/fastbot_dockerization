#!/bin/bash
# =============================================================================
# sim_build.sh  —  FastBot Simulation Docker Image Builder
#
# Run from docker/ folder: ~/ros2_ws/src/docker/
#
# Usage:
#   ./sim_build.sh              # build all 3 images
#   ./sim_build.sh gazebo       # build only gazebo
#   ./sim_build.sh slam         # build only slam
#   ./sim_build.sh web          # build only webapp
#   ./sim_build.sh gazebo slam  # build multiple
# =============================================================================

set -e

# ── Config ────────────────────────────────────────────────────────────────────
REPO="${DOCKERHUB_USER:-your_username}-cp22"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # docker/
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)" # ros2_ws/src/
SIM_DIR="${SCRIPT_DIR}/simulation"             # docker/simulation/

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

# ── Verify packages exist in build context ────────────────────────────────────
check_packages() {
    local missing=()
    for pkg in fastbot_description fastbot_gazebo fastbot_slam; do
        [ ! -d "${PROJECT_ROOT}/${pkg}" ] && missing+=("$pkg")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing packages at: ${PROJECT_ROOT}/"
        warn "Expected: ${missing[*]}"
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
    [ ${#targets[@]} -eq 0 ] && targets=("gazebo" "slam" "web")

    echo ""
    echo "=============================================="
    echo "  FastBot Simulation Build"
    echo "  Repo    : ${REPO}"
    echo "  Targets : ${targets[*]}"
    echo "  Context : ${PROJECT_ROOT}"
    echo "  SimDir  : ${SIM_DIR}"
    echo "=============================================="

    for t in "${targets[@]}"; do
        case "$t" in
            gazebo|slam|web) ;;
            *) error "Unknown target '${t}'. Valid: gazebo | slam | web" ;;
        esac
    done

    check_packages

    local overall_start=$(date +%s)

    for target in "${targets[@]}"; do
        case "$target" in
            gazebo)
                build_image "gazebo" \
                    "${REPO}:fastbot-ros2-gazebo" \
                    "${SIM_DIR}/Dockerfile.gazebo"
                ;;
            slam)
                build_image "slam" \
                    "${REPO}:fastbot-ros2-slam" \
                    "${SIM_DIR}/Dockerfile.slam"
                ;;
            web)
                build_image "web" \
                    "${REPO}:fastbot-ros2-webapp" \
                    "${SIM_DIR}/Dockerfile.webapp"
                ;;
        esac
    done

    local total=$(( $(date +%s) - overall_start ))

    echo ""
    echo "=============================================="
    success "All done in ${total}s"
    echo ""
    echo "  Images built:"
    docker images | grep "${REPO}" | grep -v real | \
        awk '{printf "  %-45s %s\n", $1":"$2, $7" "$8}'
    echo ""
    echo "  Push to Docker Hub:"
    for target in "${targets[@]}"; do
        case "$target" in
            gazebo) echo "    docker push ${REPO}:fastbot-ros2-gazebo" ;;
            slam)   echo "    docker push ${REPO}:fastbot-ros2-slam" ;;
            web)    echo "    docker push ${REPO}:fastbot-ros2-webapp" ;;
        esac
    done
    echo ""
    echo "  Run simulation:"
    echo "    cd simulation"
    echo "    sudo chmod 777 /tmp/.X11-unix/X1"
    echo "    docker-compose -f docker-compose.yaml up"
    echo "=============================================="
}

main "$@"