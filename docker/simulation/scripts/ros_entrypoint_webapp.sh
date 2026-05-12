#!/bin/bash
# =============================================================================
# ros_entrypoint_webapp.sh
# Starts nginx (web server) and rosbridge (ROS ↔ WebSocket) together.
# =============================================================================
set -e

source /opt/ros/${ROS_DISTRO}/setup.bash

echo "[nginx] Starting web server on port 80..."
nginx -g "daemon off;" &
NGINX_PID=$!

echo "[rosbridge] Starting rosbridge WebSocket server on port 9090..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml &
BRIDGE_PID=$!

wait $NGINX_PID $BRIDGE_PID