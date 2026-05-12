#!/bin/bash
# =============================================================================
# start_slam.sh — FastBot SLAM mode switcher with initial pose support
#
# Environment variables (set in docker-compose):
#   SLAM_MODE  = cartographer | localization | pathplanner (default: cartographer)
#   MAP_NAME   = map name key from map_poses.yaml (default: small_apartment)
#   MAP_FILE   = full path to map yaml (default: baked-in map matching MAP_NAME)
#
# Usage examples:
#   Mapping:
#     docker-compose up
#
#   Navigation with baked-in map:
#     SLAM_MODE=localization MAP_NAME=cozy_room docker-compose up
#
#   Navigation with custom saved map:
#     SLAM_MODE=localization MAP_NAME=my_map MAP_FILE=/maps/my_map.yaml \
#       docker-compose up
#
# Save map while cartographer is running:
#   docker exec -it fastbot-ros2-slam bash
#   ros2 run nav2_map_server map_saver_cli -f /maps/my_map
#   Then add my_map entry to simulation/config/map_poses.yaml and rebuild
# =============================================================================
set -e

source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

MODE=${SLAM_MODE:-cartographer}
MAP_NAME=${MAP_NAME:-small_apartment}
POSES_FILE=/ros2_ws/map_poses.yaml

echo "=============================================="
echo " FastBot SLAM"
echo " Mode     : ${MODE}"
echo " Map name : ${MAP_NAME}"
echo "=============================================="

# ── Helper: read a value from map_poses.yaml using python3 ────────────────────
get_pose_value() {
    local map=$1
    local field=$2
    python3 -c "
import yaml, sys
with open('${POSES_FILE}') as f:
    data = yaml.safe_load(f)
if '${map}' not in data:
    print(0.0)
    sys.exit(0)
val = data['${map}']['initial_pose'].get('${field}', 0.0)
print(val)
"
}

# ── Helper: publish initial pose ──────────────────────────────────────────────
publish_initial_pose() {
    local map_name=$1
    local x=$(get_pose_value "$map_name" x)
    local y=$(get_pose_value "$map_name" y)
    local yaw=$(get_pose_value "$map_name" yaw)

    echo " Publishing initial pose for map '${map_name}': x=${x} y=${y} yaw=${yaw}"

    # Convert yaw to quaternion z and w
    # For 2D: qz = sin(yaw/2), qw = cos(yaw/2)
    local qz=$(python3 -c "import math; print(math.sin(${yaw}/2))")
    local qw=$(python3 -c "import math; print(math.cos(${yaw}/2))")

    # Wait for AMCL to be ready then publish
    sleep 5
    ros2 topic pub --once /initialpose \
        geometry_msgs/msg/PoseWithCovarianceStamped \
        "{
            header: {frame_id: 'map'},
            pose: {
                pose: {
                    position: {x: ${x}, y: ${y}, z: 0.0},
                    orientation: {x: 0.0, y: 0.0, z: ${qz}, w: ${qw}}
                }
            }
        }" &
}

# ── Main ──────────────────────────────────────────────────────────────────────
case "$MODE" in

    cartographer)
        echo " Starting Cartographer (mapping mode)..."
        echo " To save map:"
        echo "   docker exec -it fastbot-ros2-slam bash"
        echo "   ros2 run nav2_map_server map_saver_cli -f /maps/my_map"
        echo "=============================================="
        exec ros2 launch fastbot_slam cartographer.launch.py
        ;;

    localization)
        # Resolve map file path
        if [ -n "$MAP_FILE" ]; then
            RESOLVED_MAP=$MAP_FILE
        else
            RESOLVED_MAP=/ros2_ws/install/fastbot_slam/share/fastbot_slam/maps/${MAP_NAME}.yaml
        fi

        if [ ! -f "$RESOLVED_MAP" ]; then
            echo " ERROR: Map file not found: ${RESOLVED_MAP}"
            echo " Available baked-in maps:"
            ls /ros2_ws/install/fastbot_slam/share/fastbot_slam/maps/*.yaml 2>/dev/null | \
                xargs -I{} basename {} .yaml | sed 's/^/   - /'
            echo " Custom maps in volume:"
            ls /maps/*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | \
                sed 's/^/   - /' || echo "   (none)"
            exit 1
        fi

        echo " Map file   : ${RESOLVED_MAP}"
        echo " Starting localization + AMCL..."
        echo "=============================================="

        # Publish initial pose in background after AMCL starts
        publish_initial_pose "$MAP_NAME" &

        exec ros2 launch fastbot_slam localization.launch.py map:=${RESOLVED_MAP}
        ;;

    pathplanner)
        echo " Starting Nav2 path planner..."
        echo "=============================================="
        exec ros2 launch fastbot_slam pathplanner.launch.py
        ;;

    *)
        echo " ERROR: Unknown SLAM_MODE '${MODE}'"
        echo " Valid: cartographer | localization | pathplanner"
        exit 1
        ;;
esac