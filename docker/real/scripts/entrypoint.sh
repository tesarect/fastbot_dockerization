#!/bin/bash
# =============================================================================
# entrypoint.sh — ROS2 entrypoint for real robot containers
# =============================================================================
set -e

source /opt/ros/humble/setup.bash

if [ -f /ros2_ws/install/setup.bash ]; then
    source /ros2_ws/install/setup.bash
fi

# Stop stale daemon so fresh DDS discovery works on first ros2 command
ros2 daemon stop 2>/dev/null || true

exec "$@"
