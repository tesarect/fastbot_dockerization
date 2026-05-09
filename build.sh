#!/bin/bash
# =============================================================================
# build.sh  —  FastBot Docker Image Builder
#
# Run from project root: fastbot_ros2_docker/
#
# Usage:
#   ./simulation/build.sh              # build all 3 images
#   ./simulation/build.sh gazebo       # build only gazebo
#   ./simulation/build.sh slam         # build only slam
#   ./simulation/build.sh web          # build only webapp
#   ./simulation/build.sh gazebo slam  # build multiple specific images
# =============================================================================

set -e

# ── Config ────────────────────────────────────────────────────────────────────
REPO="${DOCKERHUB_USER:-your_username}-cp22"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
SIM_DIR="${PROJECT_ROOT}/simulation"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
log()     { echo -e "${BLUE}[build]${NC} $*"; }
success() { echo -e "${GREEN}[done] ${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn] ${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*"; exit 1; }

# ── Verify build context ──────────────────────────────────────────────────────
check_packages() {
    local missing=()
    for pkg in fastbot_description fastbot_gazebo fastbot_slam; do
        [ ! -d "${PROJECT_ROOT}/${pkg}" ] && missing+=("$pkg")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing packages at project root: ${missing[*]}"
        warn "Copy them first:"
        for pkg in "${missing[@]}"; do
            echo "  cp -r ~/ros2_ws/src/fastbot/${pkg} ${PROJECT_ROOT}/"
        done
        echo ""
        read -rp "Continue anyway? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi
}

# ── Build a single image ──────────────────────────────────────────────────────
build_image() {
    local name=$1        # gazebo | slam | web
    local tag=$2         # full image tag
    local dockerfile=$3  # path to Dockerfile

    echo ""
    log "Building ${tag} ..."
    echo "──────────────────────────────────────────────"

    local start=$(date +%s)

    docker build \
        -f "${dockerfile}" \
        -t "${tag}" \
        "${PROJECT_ROOT}"

    local end=$(date +%s)
    local elapsed=$((end - start))

    success "${tag} built in ${elapsed}s"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    # Determine which images to build
    local targets=("$@")
    if [ ${#targets[@]} -eq 0 ]; then
        targets=("gazebo" "slam" "web")
    fi

    echo ""
    echo "=============================================="
    echo "  FastBot Docker Build"
    echo "  Repo    : ${REPO}"
    echo "  Targets : ${targets[*]}"
    echo "  Context : ${PROJECT_ROOT}"
    echo "=============================================="

    # Validate targets
    for t in "${targets[@]}"; do
        case "$t" in
            gazebo|slam|web) ;;
            *) error "Unknown target '${t}'. Valid: gazebo slam web" ;;
        esac
    done

    # Check packages exist at project root
    check_packages

    # Build requested images
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
                    "${SIM_DIR}/Dockerfile.web"
                ;;
        esac
    done

    local overall_end=$(date +%s)
    local total=$((overall_end - overall_start))

    echo ""
    echo "=============================================="
    success "All done in ${total}s"
    echo ""
    echo "  Images built:"
    docker images | grep "${REPO}" | awk '{printf "  %-45s %s\n", $1":"$2, $7" "$8}'
    echo ""
    echo "  Next steps:"
    echo "    cd simulation"
    echo "    xhost +local:docker"
    echo "    docker compose -f docker-compose.yaml -f docker-compose.prod.yaml up"
    echo "=============================================="
}

main "$@"