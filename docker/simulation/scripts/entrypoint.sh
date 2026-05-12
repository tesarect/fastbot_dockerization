#!/bin/bash
# Sources ROS 2 and workspace setup files, then executes the given command.
set -e

# Source ROS 2 base installation
source /opt/ros/${ROS_DISTRO}/setup.bash

# Source workspace overlay if it has been built
if [ -f /ros2_ws/install/setup.bash ]; then
    source /ros2_ws/install/setup.bash
fi

# Set Gazebo model path so gzserver finds fastbot_description meshes
# export GAZEBO_MODEL_PATH=/ros2_ws/install/fastbot_description/share:/ros2_ws/install/fastbot_gazebo/share/fastbot_gazebo/models:/usr/share/gazebo-11/models
# export GAZEBO_RESOURCE_PATH=/ros2_ws/install/fastbot_description/share:/usr/share/gazebo-11


# Execute the command passed to the container (e.g. ros2 launch ...)
exec "$@"