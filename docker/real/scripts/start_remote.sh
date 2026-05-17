#!/bin/bash
# =============================================================================
# start_remote.sh — FastBot Remote Services
# Runs on external laptop — connects to Pi via Husarnet/Tailscale
#
# Starts:
#   1. ROSBridge WebSocket (port 9090)
#   2. Web Video Server   (port 11315)
#   3. TF2 Web Republisher
# =============================================================================
set -e

echo "=============================================="
echo "  FastBot Remote Services"
echo "  CYCLONEDDS_URI: ${CYCLONEDDS_URI:-not set}"
echo "  ROS_DOMAIN_ID:  ${ROS_DOMAIN_ID:-0}"
echo "=============================================="

# Wait for DDS peer discovery
echo "Waiting for Pi robot topics..."
sleep 3

# Check if Pi topics are visible
echo "Checking topics from Pi..."
ros2 topic list 2>/dev/null || echo "Warning: No topics yet — Pi may still be starting"
echo ""

# Start ROSBridge WebSocket (port 9090)
echo "[1/3] Starting ROSBridge on port 9090..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml \
    address:=0.0.0.0 &
sleep 2

# Start Web Video Server (port 11315)
echo "[2/3] Starting Web Video Server on port 11315..."
ros2 run web_video_server web_video_server \
    --ros-args -p port:=11315 -p address:="0.0.0.0" &
sleep 1

# Start TF2 Web Republisher
echo "[3/3] Starting TF2 Web Republisher..."
ros2 run tf2_web_republisher_py tf2_web_republisher &

echo ""
echo "=============================================="
echo "  All services started!"
echo "  ROSBridge:       ws://localhost:9090"
echo "  Web Video:       http://localhost:11315"
echo ""
echo "  To run RViz in another terminal:"
echo "    docker exec -it fastbot-remote rviz2"
echo "=============================================="

wait
