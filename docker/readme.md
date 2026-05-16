
# Available images

# 2. Start containers
cd ~/ros2_ws/src/fastbot_ros2_docker/simulation
docker-compose -f docker-compose.yaml up

# 3. On host — verify topics visible
source ~/ros2_ws/install/setup.bash
ros2 topic list
# should show /fastbot/scan, /fastbot/odom, /map etc.

# 4.1 Run RViz on host to visualize map
rviz2 -d ~/ros2_ws/src/fastbot/fastbot_slam/rviz/nav.rviz
rviz2 -d ~/ros2_ws/src/fastbot_description/rviz/fastbot.rviz

# 4.2 Run RViz on docker to visualize map
docker exec -it fastbot-ros2-gazebo bash -c \
"source install/setup.bash && \
rviz2 -d src/fastbot_description/rviz/fastbot.rviz"

# 5. Misl commands
### Topics echo/info
  docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && ros2 topic echo /map --once"

### Topics list
  docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && ros2 topic list"

### Teleop
  docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args --remap cmd_vel:=fastbot/cmd_vel"

save a map:
# In a new terminal — exec into slam container
# Save map to the volume mount point
```
docker exec -it fastbot-ros2-slam bash
```
inside container:
```
ros2 run nav2_map_server map_saver_cli \
  -f /maps/my_map \
  --ros-args -p save_map_timeout:=5.0
```
or
```
docker exec -it fastbot-ros2-slam bash -c \
"source /opt/ros/humble/setup.bash &&
 source /ros2_ws/install/setup.bash &&
 ros2 run nav2_map_server map_saver_cli \
  -f /maps/my_map1 \
  --ros-args -p save_map_timeout:=5.0"
```

# Then after saving, switch to navigation:
```
docker-compose -f docker-compose.yml down
SLAM_MODE=localization MAP_FILE=/maps/my_map.yaml \
  docker-compose -f docker-compose.yml up
```

# List files inside a named volume
# Check what's in the fastbot-maps volume
```
docker run --rm \
  -v fastbot-maps:/maps \
  alpine ls -la /maps
```
or
```
docker exec -it fastbot-ros2-slam bash
ls -la /maps/
```
or
```
docker exec -it fastbot-ros2-slam bash -c \
"ls -la /maps/"
```
expected output:
```
total 56
drwxr-xr-x    2 root     root          4096 May 11 05:27 .
drwxr-xr-x    1 root     root          4096 May 11 05:29 ..
-rw-r--r--    1 root     root         17488 May 11 05:25 my_map.pgm
-rw-r--r--    1 root     root           124 May 11 05:25 my_map.yaml
-rw-r--r--    1 root     root         17488 May 11 05:27 my_map1.pgm
-rw-r--r--    1 root     root           125 May 11 05:27 my_map1.yaml
```
# To explicitly remove volume
```
docker volume rm fastbot-maps
```
# Inspect Volume
```
$ docker volume inspect fastbot-maps
[
    {
        "CreatedAt": "2026-05-11T05:09:29Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "simulation",
            "com.docker.compose.version": "1.25.0",
            "com.docker.compose.volume": "fastbot-maps"
        },
        "Mountpoint": "/var/lib/docker/volumes/fastbot-maps/_data",
        "Name": "fastbot-maps",
        "Options": null,
        "Scope": "local"
    }
]
```

# Load saved maps
TODO: whats the default map and list the available maps
## From Volume space
```
docker-compose -f docker-compose.yml down

SLAM_MODE=localization MAP_NAME=my_map MAP_FILE=/maps/my_map.yaml \
  docker-compose up
```
## From images existing space
```bash
SLAM_MODE=localization MAP_NAME=room_map docker-compose up
# or
SLAM_MODE=localization MAP_NAME=room_map \
  docker-compose -f docker-compose.yml up
```

# Set `initialpose`
> [!IMPORTANT:] Default maps will run with inital pose automaticaly if defined under `/ros2_ws/map_poses.yaml`(inside fastbot-ros2-slam image).If its not defined, please do the `2D pose estimate` from rviz.
```
docker exec -it fastbot-ros2-slam bash -c \
"source /ros2_ws/install/setup.bash &&
ros2 topic pub --once /initialpose \
  geometry_msgs/msg/PoseWithCovarianceStamped \
  '{header: {frame_id: "map"}, 
    pose: {pose: {position: {x: 0.0, y: 0.0, z: 0.0}, 
    orientation: {w: 1.0}}}}'"
```
-------------------------------------------------------------------------

xhost +local:docker
docker run --rm -it \
  --name gazebo \
  --net=host \
  --ipc=host \
  -e DISPLAY=$DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  tesarect-cp22:fastbot-ros2-gazebo


---------------------------------------------------------------------------
ros2 launch fastbot_gazebo one_fastbot_room.launch.py

ON HOST
user:~$ cat /proc/$(pgrep gzserver)/environ | tr '\0' '\n' | grep GAZEBO
GAZEBO_MASTER_URI=http://localhost:11345
GAZEBO_PLUGIN_PATH=/usr/share/gazebo-11
GAZEBO_MODEL_DATABASE_URI=
GAZEBO_RESOURCE_PATH=/usr/share/gazebo-11
GAZEBO_MODEL_PATH=/home/user/ros2_ws/install/fastbot_gazebo/share/fastbot_gazebo/models::/usr/share/gazebo-11/models

$ echo $GAZEBO_MODEL_PATH
/usr/share/gazebo-11/models:/usr/share/gazebo-11/models:/usr/share/gazebo-9/models:/usr/share/gazebo/models_robox


# Real Environment
Join code for group tesarect-fastbot is:
karthikn.balasubramanian@gmail.com/gErnkJZzEB3GRVyKczPz5f

You can use it in Husarnet CLI like this:
sudo husarnet join karthikn.balasubramanian@gmail.com/gErnkJZzEB3GRVyKczPz5f

Husarnet join code:
fc94:47a0:bab5:a53b:480e:0ed2:ae6c:fa61


$ ros2 topic list
/parameter_events
/rosout
fastbot@fastbot:~/ros2_ws/src/docker/real$ docker-compose up -d
Creating fastbot-ros2-real ... done
Creating fastbot-ros2-slam-real ... done
fastbot@fastbot:~/ros2_ws/src/docker/real$ ros2 topic list
/clock
/constraint_list
/diagnostics
/fastbot/camera_info
/fastbot/cmd_vel
/fastbot/encoder_vals
/fastbot/image_raw
/fastbot/image_raw/compressed
/fastbot/image_raw/compressedDepth
/fastbot/image_raw/theora
/fastbot/joint_states
/fastbot/motor_vels
/fastbot/odom
/fastbot/scan
/fastbot_robot_description
/landmark_poses_list
/lslidar_driver_node/transition_event
/lslidar_order
/map
/parameter_events
/rosout
/scan_matched_points2
/submap_list
/tf
/tf_static
/trajectory_node_list
fastbot@fastbot:~/ros2_ws/src/docker/real$ docker exec -it fastbot-ros2-real bash -c "source /opt/ros/humble/setup.sh && source /ros2_ws/install/setup.sh && ros2 topic list"
/clock
/constraint_list
/diagnostics
/fastbot/camera_info
/fastbot/cmd_vel
/fastbot/encoder_vals
/fastbot/image_raw
/fastbot/image_raw/compressed
/fastbot/image_raw/compressedDepth
/fastbot/image_raw/theora
/fastbot/joint_states
/fastbot/motor_vels
/fastbot/odom
/fastbot/scan
/fastbot_robot_description
/landmark_poses_list
/lslidar_driver_node/transition_event
/lslidar_order
/map
/parameter_events
/rosout
/scan_matched_points2
/submap_list
/tf
/tf_static
/trajectory_node_list

$ cat /etc/hosts | grep managed
fc94:47a0:bab5:a53b:480e:0ed2:ae6c:fa61 fastbot # managed by Husarnet
fc94:b2de:c13c:c1ef:e52b:4880:6ae2:32b1 husarnet-local # managed by Husarnet
fc94:b2de:c13c:c1ef:e52b:4880:6ae2:32b1 rosman # managed by Husarnet

sudo systemctl stop fastbot.service
# or
docker-compose down

# Then start with what you need:
docker-compose -f docker-compose.yaml up -d                                    # local + slam
docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml up -d   # remote + slam

1. Connecting from external machine
After starting husarnet compose on Pi:
On external machine (laptop):
bash# Set ROS environment
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0
export CYCLONEDDS_URI=file:///home/rosman/cyclonedds-husarnet.xml

# Verify Husarnet is connected
husarnet status

# List topics from Pi
ros2 topic list

# Run RViz
rviz2

The laptop needs ROS2 Humble installed. The cyclonedds-husarnet.xml on the laptop should have the correct peer hostnames matching what Husarnet assigned.

2. Topics visible on Pi host with Husarnet config
Yes — but with one condition. The Pi host needs to use the same DDS config as the containers:
bash# On Pi host — match the container's DDS config
export CYCLONEDDS_URI=file:///home/fastbot/ros2_ws/src/docker/real/config/cyclonedds-husarnet.xml
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0

ros2 topic list

Without setting CYCLONEDDS_URI on the host, it uses default multicast while containers use Husarnet unicast — they're on different DDS networks and can't see each other.
Summary:
ScenarioContainer configHost needsLocalno CYCLONEDDS_URInothing (default multicast)Husarnetcyclonedds-husarnet.xmlsame XML exported
So when running husarnet compose, set the same CYCLONEDDS_URI on the Pi host too — then both host and external machine see all topics.


