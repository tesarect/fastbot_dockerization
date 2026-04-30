#!/bin/bash
# =============================================================================
# entrypoint.sh
# Sources ROS 2 and workspace setup files, then executes the given command.
# =============================================================================
set -e

# Source ROS 2 base installation
source /opt/ros/${ROS_DISTRO}/setup.bash

# Source workspace overlay if it has been built
if [ -f /ros2_ws/install/setup.bash ]; then
    source /ros2_ws/install/setup.bash
fi

# Execute the command passed to the container (e.g. ros2 launch ...)
exec "$@"