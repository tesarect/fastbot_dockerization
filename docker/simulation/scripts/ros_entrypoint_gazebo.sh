#!/bin/bash
# 1. Installs rosdep dependencies from the mounted source
# 2. Builds the workspace with colcon
# 3. Launches Gazebo simulation + rosbridge
#
# The fastbot source is NOT baked into the image — it is mounted from the
# host at runtime:  ~/ros2_ws/src/fastbot  →  /ros2_ws/src/fastbot
set -e

source /opt/ros/${ROS_DISTRO}/setup.bash

echo "[setup] Installing rosdep dependencies from mounted source..."
rosdep install --from-paths /ros2_ws/src --ignore-src -r -y

echo "[setup] Building workspace..."
cd /ros2_ws
colcon build --symlink-install

source /ros2_ws/install/setup.bash

echo "[Gazebo] Starting FastBot Gazebo simulation..."
ros2 launch fastbot_gazebo one_fastbot_room.launch.py &
GAZEBO_PID=$!

echo "[rosbridge] Starting rosbridge WebSocket server on port 9090..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml &
BRIDGE_PID=$!

# Keep container alive; exit if either process dies
wait $GAZEBO_PID $BRIDGE_PID