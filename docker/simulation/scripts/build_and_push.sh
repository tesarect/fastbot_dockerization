#!/bin/bash
# =============================================================================
# build_and_push.sh
# Builds all Docker images in the correct layer order and pushes to Docker Hub.
#
# Layer order (each FROM the one above):
#   ubuntu:22.04
#       └── fastbot-ubuntu-base      (Dockerfile.base)
#               └── fastbot-ros2-base    (Dockerfile.ros2-base)
#                       ├── fastbot-ros2-gazebo  (Dockerfile.gazebo)
#                       ├── fastbot-ros2-slam    (Dockerfile.slam)
#                       └── fastbot-ros2-webapp  (Dockerfile.webapp)
#
# Usage:
#   chmod +x build_and_push.sh
#
#   # Build + test ONE layer at a time (recommended first time):
#   ./build_and_push.sh <username> ubuntu    # stop after ubuntu-base
#   ./build_and_push.sh <username> ros2      # stop after ros2-base
#   ./build_and_push.sh <username> gazebo    # stop after gazebo image
#   ./build_and_push.sh <username> slam      # stop after slam image
#   ./build_and_push.sh <username> webapp    # stop after webapp image
#   ./build_and_push.sh <username> all       # build all layers + push (default)
#
# Testing a single layer interactively after stopping:
#   docker run --rm -it fastbot-ubuntu-base bash
#   docker run --rm -it fastbot-ros2-base bash
#   docker run --rm -it --network host <repo>:fastbot-ros2-gazebo bash
# =============================================================================
set -e

USERNAME=${1:-"your_username"}
STOP_AT=${2:-"all"}
REPO="${USERNAME}-cp22"

echo "=============================================="
echo " FastBot Docker Build"
echo " Docker Hub repo : ${REPO}"
echo " Build until     : ${STOP_AT}"
echo "=============================================="

test_hint() {
  local image=$1; shift
  echo ""
  echo "  Built: ${image}"
  echo "  Test:  docker run --rm -it ${image} bash"
  echo "         $@"
  echo ""
}

# Layer 1 — Ubuntu base
echo ""
echo "[1/5] ▶️ fastbot-ubuntu-base ..."
docker build -f Dockerfile.ubuntu-base -t fastbot-ubuntu-base:latest .
test_hint "fastbot-ubuntu-base" \
  "curl --version | git --version | cat /etc/os-release"
[ "${STOP_AT}" = "ubuntu" ] && exit 0

# Layer 2 — ROS 2 Humble base
echo "[2/5] ▶️ fastbot-ros2-base ..."
docker build -f Dockerfile.ros2-base -t fastbot-ros2-base:latest .
test_hint "fastbot-ros2-base" \
  "source /opt/ros/humble/setup.bash && ros2 --help && rosdep --version"
[ "${STOP_AT}" = "ros2" ] && exit 0

# Layer 3 — Gazebo
echo "[3/5] ▶️ ${REPO}:fastbot-ros2-gazebo ..."
docker build -f Dockerfile.gazebo -t ${REPO}:fastbot-ros2-gazebo .
test_hint "${REPO}:fastbot-ros2-gazebo" \
  "source /ros2_ws/install/setup.bash && ros2 launch fastbot_gazebo --show-args"
[ "${STOP_AT}" = "gazebo" ] && exit 0

# Layer 4 — SLAM
echo "[4/5] ▶️ ${REPO}:fastbot-ros2-slam ..."
docker build -f Dockerfile.slam -t ${REPO}:fastbot-ros2-slam .
test_hint "${REPO}:fastbot-ros2-slam" \
  "source /ros2_ws/install/setup.bash && ros2 pkg list | grep cartographer"
[ "${STOP_AT}" = "slam" ] && exit 0

# Layer 5 — Webapp
echo "[5/5] ▶️ ${REPO}:fastbot-ros2-webapp ..."
docker build -f Dockerfile.webapp -t ${REPO}:fastbot-ros2-webapp .
test_hint "${REPO}:fastbot-ros2-webapp" \
  "nginx -t && ros2 pkg list | grep rosbridge"
[ "${STOP_AT}" = "webapp" ] && exit 0

# # Push service images
# echo ""
# echo "Pushing to Docker Hub (${REPO}) — make sure you ran: docker login"
# for SERVICE in gazebo slam webapp; do
#   echo "  Pushing ${REPO}:fastbot-ros2-${SERVICE} ..."
#   docker push ${REPO}:fastbot-ros2-${SERVICE}
# done

echo ""
docker images | grep -E "fastbot|${REPO}"
echo ""
echo "Done! Start the stack:  DOCKERHUB_USER=${USERNAME} docker-compose up"