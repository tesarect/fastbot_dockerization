#!/bin/bash
# 1. Installs rosdep dependencies from the mounted source
# 2. Builds only the fastbot_slam package (gazebo container builds the rest)
# 3. Launches Cartographer SLAM
#
# The fastbot source is NOT baked into the image — it is mounted from the
# host at runtime:  ~/ros2_ws/src/fastbot  →  /ros2_ws/src/fastbot
set -e

source /opt/ros/${ROS_DISTRO}/setup.bash

echo "[setup] Installing rosdep dependencies from mounted source..."
rosdep install --from-paths /ros2_ws/src --ignore-src -r -y

echo "[setup] Building fastbot_slam package..."
cd /ros2_ws
colcon build --symlink-install --packages-select fastbot_slam fastbot_description

source /ros2_ws/install/setup.bash

echo "[SLAM] Starting Cartographer SLAM..."
ros2 launch fastbot_slam cartographer.launch.py