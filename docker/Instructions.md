
# Simulation
Images for simulation
  - fastbot-ros2-gazebo
  - fastbot-ros2-slam
  - fastbot-ros2-webapp

## Build or Pull images
There is a build helper script to build all the images
```bash
cd ~/ros2_ws/src/fastbot_ros2_docker/docker

# build helper
./sim_build.sh
# or build manually
docker build simulation/ [TODO: fill the commands]
```
To pull the images from dockerhub
```bash

```

## Start containers
```bash
cd ~/ros2_ws/src/fastbot_ros2_docker/simulation

# starts all 3 containers
docker-compose -f docker-compose.yaml up -d

# start individual container
docker-compose -f docker-compose.yaml up -d gazebo
```

## Visualize 
#### Through Container
```bash
docker exec -it fastbot-ros2-gazebo bash -c \
"source install/setup.bash && \
rviz2 -d src/fastbot_description/rviz/fastbot.rviz"
```

#### Through Host
```bash
rviz2 -d ~/ros2_ws/src/fastbot/fastbot_slam/rviz/nav.rviz
rviz2 -d ~/ros2_ws/src/fastbot_description/rviz/fastbot.rviz
```

## View Topics 
#### Through Container
```bash
docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && ros2 topic list"
```
#### Through Host
```bash
source ~/ros2_ws/install/setup.bash
ros2 topic list
```

## Maps
By default cartographer node will be running.
### Create a new map
Keep the `gazebo` and `slam` running along with `rviz`, move the robot around the space either through teleop or throug webinterface.
```bash
# Teleop
docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args --remap cmd_vel:=fastbot/cmd_vel"
```
Once the area is covered save the map  to a volume mount point using
```bash
# Save map to Volume
docker exec -it fastbot-ros2-slam bash -c \
"source /opt/ros/humble/setup.bash &&
 source /ros2_ws/install/setup.bash &&
 ros2 run nav2_map_server map_saver_cli \
  -f /maps/my_map1 \
  --ros-args -p save_map_timeout:=5.0"
```
or, enter into the container
```bash
docker exec -it fastbot-ros2-slam bash
```
then save the map to a volume mount point
```bash
ros2 run nav2_map_server map_saver_cli \
  -f /maps/my_map \
  --ros-args -p save_map_timeout:=5.0
```

### Load Maps / Switching to Navigation
If you are still running the cartographer node, please bring it down
```bash
docker ps
cd ~/ros2_ws/src/fastbot_ros2_docker/docker/simulation
docker-compose ps
# Then bring down respective container
docker-compose -f docker-compose.yaml down
```
#### From Volume
Please visit [help yourself](#list-files-inside-a-named-volumelist-user-saved-maps) if you need help in inspecting or list maps under volume space
```bash
SLAM_MODE=localization MAP_NAME=my_map MAP_FILE=/maps/my_map.yaml \
  docker-compose up
```
#### From Pre-existing (available inside container)
```bash
SLAM_MODE=localization MAP_NAME=room_map docker-compose up
# or
SLAM_MODE=localization MAP_NAME=room_map \
  docker-compose -f docker-compose.yaml up
```


### Set `initialpose`
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

# Real Environment (Fastbot)
These are the images thats supposed to be running mandatorly for bringing up the fastbot
  - `fastbot-ros2-real`       (responsible for drivers lidar, serial motor and camera)
  - `fastbot-ros2-slam-real`  (runs cartographer for mapping by default)
  - `fastbot-remote`          (an optional image thats helps to connect to fastbot remotely)

### Compose types:
  - local
    - robot -> `fastbot-ros2-real` (Default running service on fastbot during boot)
      ```bash
      docker-compose -f docker-compose.yaml up -d robot
      ```
    - robot + slam  -> `fastbot-ros2-real` + `fastbot-ros2-slam-real`
      ```bash
      docker-compose -f docker-compose.yaml up -d
      ```
  - remote (through husarnet)
    - robot -> `fastbot-ros2-real`
      ```bash
      docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml up -d robot
      ```
    - robot + slam  -> `fastbot-ros2-real` + `fastbot-ros2-slam-real`
      ```bash
      docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml up -d
      ```




## Local Connection
Make sure the `real` and `slam-real` are up and running.

### Visualize from fastbot / host(Pi)
> [NOTE] : This preperation works for both local and remote(husarnet) setup
The running container `real` and `slam-real` are base images without gui. So you will be forced to use local host(Pi/fastbot) to visualize. This same configuraiton is also used to connect to fastbot locally or as a host while remote connection is established, so make sure you first export these env variables on the fastbot(Pi) as host.
#### from host
No additional changes neede. fastbot rose nodes are visible directly on the host
#### for remote
```bash
# On Pi host — match the container's DDS config
export CYCLONEDDS_URI=file:///home/fastbot/ros2_ws/src/docker/real/config/cyclonedds-husarnet.xml
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0

ros2 topic list

ros2 daemon stop #(optional if topics still not visible, then procede with topic listing)
```
Without setting CYCLONEDDS_URI on the host, it uses default multicast while containers use Husarnet unicast — they're on different DDS networks and can't see each other.

So when running husarnet compose, set the same CYCLONEDDS_URI on the Pi host too — then both host and external machine see all topics.


Check topics directly on the container
```bash
docker exec -it fastbot-ros2-real bash -c "source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash && 
  ros2 topic list"
```
Check topics on host
```bash
ros2 topic list
```


## Remote Connection
### pre-req
By default the fastbot will be running just the essential(camera, lidar and serial motor drivers). To establish a remote connection, bring the default running service down first

```bash
sudo systemctl stop fastbot.service
```
> [!WARNING]: To avoid stale containers its better to bring dontainer down completely. Because the `fastbot.service` just stops the container and does not downs the container completely, so that during shutdown, `<container> stop` is quicker that `<container> down`. So
```bash
cd docker/real # make sure you switch to docker files path
# list out running containers
docker-compose ps
#bring the default down
docker-compose -f docker-compose.yaml down
```
### Bring up the Remote connect on the Fastbot(Pi)
The connection is established through Husarnet and all necessary setups are done through  `docker-compose.husarnet.yaml`

```bash
cd docker/real
docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml up -d

# To bring it down
docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml down -d
```

### Connecting from external machine
Make sure you have `docker` and `docker-compose`/`docker compoes` installed on remote machine.

#### build & run remote connection container
```bash
cd ~/ros2_ws/src

docker build \
  -f docker/real/Dockerfile.remote \
  -t tesarect-cp22:fastbot-ros2-remote .

# Run
cd ~/ros2_ws/src/docker/real
docker compose -f docker-compose.remote.yaml up -d

# To bring it down
docker compose -f docker-compose.remote.yaml down -d
```
##### Check for connection establishment
Check for topics availability on 
###### 1. Remote Container
```bash
docker exec -it fastbot-remote bash -c "source /opt/ros/humble/setup.bash && 
  ros2 topic list"
```

###### 2. Remote host
This step needs ros2 installed on your local machine(remote w.r.t fastbot)
if so check for `ROS_DOMAIN_ID`. Our container are set to `0`, if your local is different, set it to `0`. Then you shoudl see fastbots topic.
```bash
ros2 topic list
```
If not visible, copy the `cyclonedds-husarnet.xml` from `docker/real/condif` and place it in you home path, then export the following env variables.
> [!NOTE]: your device need to be added to husarnet dashboard for this step.

```bash
# Set ROS environment
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp  # Installation required
export ROS_DOMAIN_ID=0
export CYCLONEDDS_URI=file:///home/rosman/cyclonedds-husarnet.xml

# Verify Husarnet is connected
husarnet status

# List topics from Pi
ros2 topic list

# Run RViz
rviz2
```


## Map Generation
### On Simulation
Make sure `gazebo` and `slam` container are running on the Fastbot.
### On Fastbot
#### Through host
The `real` and `slam-real` image are not full desktop or gui based. 
Instead you can run `rviz2` on the fastbot(host) directly while `real` and `slam-real` are running. Look at the section visualize through host, [follow this](#visualize-from-fastbot--hostpi). Once you can see the topics of fastbot, you can directly fire up `rviz2` on the host (if installed) to visualize.

```bash
# bring up rviz saved config from the repo
rviz2 -d ~/ros2_ws/src/fastbot_slam/rviz/default.rviz 

docker exec -it fastbot-ros2-slam-real bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args --remap cmd_vel:=fastbot/cmd_vel"
```

#### Through Remote
And make sure `remote` container is running on the remote machine.
Check if topics are visible and fire up rviz.
```bash
# Inside remote container
docker exec -it fastbot-remote bash -c \
  "source /opt/ros/humble/setup.bash && \
   source /ros2_ws/install/setup.bash 2>/dev/null || true && \
   rviz2 -d /opt/ros/humble/share/nav2_bringup/rviz/nav2_default_view.rviz"
```

## Help yourself

### logs
To view logs of individual containers
```bash
docker ps
# Then
docker logs <container>
docker logs -f <container>
docker logs --tail 100 <container>
docker logs --since 1h <container>
```
To view the whole compose's logs
> [!NOTE]: For docker compose you need to be in the path where the compose files reside
```bash
docker-compose ps
# Then
docker-compose logs
docker-compose logs -f
docker-compose logs --tail=100
docker-compose logs <service>
docker-compose logs -f <service>
```
### List files inside a named volume(List user saved maps)
```bash
docker run --rm \
  -v fastbot-maps:/maps \
  alpine ls -la /maps
```
or
```bash
docker exec -it fastbot-ros2-slam bash
ls -la /maps/
```
or
```bash
docker exec -it fastbot-ros2-slam bash -c \
"ls -la /maps/"
```
expected output:
```bash
total 56
drwxr-xr-x    2 root     root          4096 May 11 05:27 .
drwxr-xr-x    1 root     root          4096 May 11 05:29 ..
-rw-r--r--    1 root     root         17488 May 11 05:25 my_map.pgm
-rw-r--r--    1 root     root           124 May 11 05:25 my_map.yaml
-rw-r--r--    1 root     root         17488 May 11 05:27 my_map1.pgm
-rw-r--r--    1 root     root           125 May 11 05:27 my_map1.yaml
```
#### To explicitly remove volume
```bash
docker volume rm fastbot-maps
```
#### Inspect Volume
```bash
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

### For Remote ip6 inspection
```bash
$ cat /etc/hosts | grep managed
fc94:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx fastbot # managed by Husarnet
fc94:yyyy:yyyy:yyyy:yyyy:yyyy:yyyy:yyyy husarnet-local # managed by Husarnet
fc94:yyyy:yyyy:yyyy:yyyy:yyyy:yyyy:yyyy remote/remote container # managed by Husarnet

$ husarnet status
# or
$ nmcli device status
DEVICE   TYPE      STATE                   CONNECTION         
eno1     ethernet  connected               Wired connection 1 
hnet0    tun       connected (externally)  hnet0              
docker0  bridge    connected (externally)  docker0            
lo       loopback  unmanaged  
```

### Expected topics when fastbot container not running
```bash
$ ros2 topic list
/parameter_events
/rosout
```

### Expected topics when fastbot container up and running
```bash
$ ros2 topic list
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
```