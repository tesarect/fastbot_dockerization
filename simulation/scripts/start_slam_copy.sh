#!/bin/bash
# =============================================================================
# start_slam.sh — SLAM mode selector
#
# Controlled via environment variables in docker-compose:
#   SLAM_MODE=cartographer   → mapping mode (default)
#   SLAM_MODE=localization   → navigation mode with AMCL
#
#   MAP_FILE=/maps/my_map.yaml → use custom map (optional)
#                                if not set, uses default baked-in map
#
# Usage examples:
#   docker-compose up                                    # mapping
#   SLAM_MODE=localization docker-compose up             # navigation (default map)
#   SLAM_MODE=localization MAP_FILE=/maps/my_map.yaml \
#     docker-compose up                                  # navigation (custom map)
#
# Saving a map while cartographer is running:
#   docker exec -it fastbot-ros2-slam bash
#   ros2 run nav2_map_server map_saver_cli -f /maps/my_map
# =============================================================================

set -e

source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

MODE=${SLAM_MODE:-cartographer}

echo "=============================================="
echo " FastBot SLAM"
echo " Mode     : ${MODE}"
echo " Map file : ${MAP_FILE:-default baked-in map}"
echo "=============================================="

case "$MODE" in
    cartographer)
        echo "Starting Cartographer (mapping mode)..."
        exec ros2 launch fastbot_slam cartographer.launch.py
        ;;
    localization)
        if [ -n "$MAP_FILE" ]; then
            echo "Starting localization with custom map: $MAP_FILE"
            exec ros2 launch fastbot_slam localization.launch.py map:=$MAP_FILE
        else
            echo "Starting localization with default baked-in map..."
            exec ros2 launch fastbot_slam localization.launch.py
        fi
        ;;
    *)
        echo "ERROR: Unknown SLAM_MODE '$MODE'"
        echo "Valid modes: cartographer, localization"
        exit 1
        ;;
esac