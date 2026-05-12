#!/bin/bash
# =============================================================================
# start_web_services.sh — Starts all webapp container services
# Called as CMD in Dockerfile.web / command: in docker-compose
# ROS 2 is already sourced by entrypoint.sh before this runs
# =============================================================================
set -e

echo "=============================================="
echo " Starting FastBot Web Services"
echo "=============================================="

# 1. ROSBridge WebSocket (port 9090) — bridges ROS topics to browser
echo "[1/3] Starting ROSBridge on port 9090..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml address:=0.0.0.0 &

sleep 2

# 2. Web Video Server (port 11315) — streams camera feed via MJPEG
echo "[2/3] Starting Web Video Server on port 11315..."
ros2 run web_video_server web_video_server \
    --ros-args -p port:=11315 -p address:="0.0.0.0" &

sleep 1

# 3. TF2 Web Republisher — republishes TF transforms for roslibjs
echo "[3/3] Starting TF2 Web Republisher..."
ros2 run tf2_web_republisher_py tf2_web_republisher &

sleep 1

# 4. Web App HTTP Server (port 8000) — serves the control panel UI
echo "[4/4] Starting Web App HTTP server on port 8000..."
cd /ros2_ws/src/fastbot_webapp && python3 -m http.server 8000 --bind 0.0.0.0 &

echo ""
echo "=============================================="
echo " All services started!"
echo "  ROSBridge:        ws://localhost:9090"
echo "  Web Video Server: http://localhost:11315"
echo "  Web App:          http://localhost:8000"
echo "=============================================="

wait