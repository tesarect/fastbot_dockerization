#!/bin/bash
# =============================================================================
# entrypoint.sh — ROS2 entrypoint for real robot containers
# =============================================================================
set -e

source /opt/ros/humble/setup.bash

if [ -f /ros2_ws/install/setup.bash ]; then
    source /ros2_ws/install/setup.bash
fi

exec "$@"
