
# 1. Simulation
Images for simulation
  - fastbot-ros2-gazebo
  - fastbot-ros2-slam
  - fastbot-ros2-webapp

## 1.1 Pre Req
### ► On TheConstruct
The Construct Rosject container looses changes related to user installation. So to prepare the Rosject for this checkpoint please run `setup_construct.sh` at initially to install and add docker to groups
```bash
cd ~/ros2_ws/src/fastbot_ros2_docker/docker
./setup_construct.sh

# source bashrc
srcrc   # alias for bashrc sourcing
# or
source ~/.bashrc
```
> [warning] TODO : remove the last line from bashrc 
### ► On Local Machine
Make sure docker and docker compose is installed and remember to load the terminal to get access to your screen before you are going to load any GUI 
```bash
xhost +local:docker
```

## 1.2 Build or Pull images
There is a build helper script to build all the images
```bash
cd ~/ros2_ws/src/fastbot_ros2_docker/docker

# build helper
./sim_build.sh                              # on TheConstruct
DOCKERHUB_USER=tesarect ./sim_build.sh web  # on your Local

# or build manually
docker build simulation/ [TODO: fill the commands]
```
To pull the images from dockerhub
```bash
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-gazebo
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-slam
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-webapp
```

## 1.3 Start containers
```bash
cd ~/ros2_ws/src/fastbot_ros2_docker/simulation

# starts all 3 containers
docker-compose -f docker-compose.yaml up -d

# start individual container
docker-compose -f docker-compose.yaml up -d gazebo
```
![running docker infos](/docs/images/00-docker-infos.png)
## 1.4 Visualize 
#### ► Through Container
works on both local and from TheConstruct
```bash
docker exec -it fastbot-ros2-gazebo bash -c \
  "source install/setup.bash && \
  rviz2 -d src/fastbot_description/rviz/fastbot.rviz"
```

#### ► Through Host
```bash
rviz2 -d ~/ros2_ws/src/fastbot/fastbot_slam/rviz/nav.rviz
rviz2 -d ~/ros2_ws/src/fastbot_description/rviz/fastbot.rviz
```

## 1.5 View Topics 
#### ► Through Container
```bash
docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && ros2 topic list"
```
#### ► Through Host
```bash
source ~/ros2_ws/install/setup.bash
ros2 topic list
```

[ Check [expected result section](#expected-topics-when-fastbot-container-not-running) ]


## 1.6 Connect to Webpage
### ► Connect from TheConstruct
Make sure `fastbot-ros2-webapp` is running and get the address from the logs.
```bash
webpage_address   # to get public url
rosbridge_address # to connect to our running ros nodes 
```
![public url from theConstruct output](/docs/images/07-public-url-through-construct.png)

[ back to [Update a map throug Webapp](#-update-a-map-throug-webapp) ]

### ► Connect from localhost
```bash
docker logs fastbot-ros2-webapp
```
Connect through the local host that gets displayed at end of this log

## 1.7 Maps
By default cartographer node will be running.
### 1.7.1 Create a new map
#### ► update a map throug Rviz-Teleop
Keep the `gazebo` and `slam` running along with `rviz`, move the robot around the space either through teleop or throug webinterface.
```bash
# Teleop
docker exec -it fastbot-ros2-slam bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args --remap cmd_vel:=fastbot/cmd_vel"
```
Once the area is covered save the map  to a volume mount point using.

#### ► update a map throug Webapp
First get [connected to webpage](#16-connect-to-webpage)

By now you should be seeing this by default(except rviz which you need to fire it up manually)

![gazebo and Rviz](/docs/images/01-sim-gazebo-rviz-from-construct.png)

After entering the webpage url you should be able to see this

![webpage control](/docs/images/02-webapp-sim-gazebo-from-construct.png)

You can update the map my moving around through the `Joystick` or `w` `a` `s` `d` keys from the webpage

![Updaing map](/docs/images/03-update-new-map-through-webapp.png)

### 1.7.2 Saving a map
there is no save option from the web page directly, so back in the construct terminal execute the following
```bash
# Save map to Volume
docker exec -it fastbot-ros2-slam bash -c \
"source /opt/ros/humble/setup.bash &&
 source /ros2_ws/install/setup.bash &&
 ros2 run nav2_map_server map_saver_cli \
  -f /maps/my_map \
  --ros-args -p save_map_timeout:=5.0"
```
> [🔁Alternatively] you can enter into the container
> ```bash
> docker exec -it fastbot-ros2-slam bash
> ```
> then save the map to a volume mount point
> ```bash
> ros2 run nav2_map_server map_saver_cli \
>   -f /maps/my_map \
>   --ros-args -p save_map_timeout:=5.0
> ```

#### Expected Output:
```bash
[INFO] [1779192793.949779236] [map_saver]: 
        map_saver lifecycle node launched. 
        Waiting on external lifecycle transitions to activate
        See https://design.ros2.org/articles/node_lifecycle.html for more information.
[INFO] [1779192793.953486223] [map_saver]: Creating
[INFO] [1779192793.953920168] [map_saver]: Configuring
[INFO] [1779192793.957831739] [map_saver]: Saving map from 'map' topic to '/maps/my_map' file
[WARN] [1779192793.957877575] [map_saver]: Free threshold unspecified. Setting it to default value: 0.250000
[WARN] [1779192793.957911098] [map_saver]: Occupied threshold unspecified. Setting it to default value: 0.650000
[WARN] [1779192793.977517225] [map_io]: Image format unspecified. Setting it to: pgm
[INFO] [1779192793.979262676] [map_io]: Received a 173 X 100 map @ 0.05 m/pix
[INFO] [1779192794.037879078] [map_io]: Writing map occupancy data to /maps/my_map.pgm
[INFO] [1779192794.039483323] [map_io]: Writing map metadata to /maps/my_map.yaml
[INFO] [1779192794.039817291] [map_io]: Map saved
[INFO] [1779192794.039859370] [map_saver]: Map saved successfully
[INFO] [1779192794.041406207] [map_saver]: Destroying
```

### 1.7.3 Load Maps / Switching to Navigation
If you are still running the cartographer node, please bring it down
```bash
docker ps

cd ~/ros2_ws/src/fastbot_ros2_docker/docker/simulation

docker-compose ps

# Then bring down respective container
docker-compose -f docker-compose.yaml down
```
### ► From Volume
Please visit [help yourself](#list-files-inside-a-named-volumelist-user-saved-maps) if you need help in inspecting or list maps under volume space

```bash
# Quick check to list maps under volume space
docker exec -it fastbot-ros2-slam bash -c \
"ls -la /maps/"

# Start Localization with existing maps
cd docker/real/
SLAM_MODE=localization MAP_NAME=my_map MAP_FILE=/maps/my_map.yaml \
  docker-compose up -d
```

### ► From Pre-existing (available inside container)
Available maps in the image
  - room_map
  - small_appartment (**Default map**)
  - small_appartment2
  - small_apartment_rotated
  - small_indoor_scenario_edited_map_hector_mapping

```bash
SLAM_MODE=localization MAP_NAME=room_map docker-compose up -d
#                 or
SLAM_MODE=localization MAP_NAME=room_map \
  docker-compose -f docker-compose.yaml up -d
```

![gazebo-Rviz with existing map](/docs/images/04-load-existing-map.png)

![webpage reflecting the same](/docs/images/05-existing-map-on-webpage.png)

### 1.7.4 Set `initialpose`
> [!IMPORTANT:] Default maps will run with inital pose automaticaly if defined under `/ros2_ws/map_poses.yaml`(inside fastbot-ros2-slam image).If its not defined, please do the `2D pose estimate` from `rviz`.

> [🔁Alternatively] through cmd
> ```bash
> docker exec -it fastbot-ros2-slam bash -c \
> "source /ros2_ws/install/setup.bash &&
> ros2 topic pub --once /initialpose \
>   geometry_msgs/msg/PoseWithCovarianceStamped \
>   '{header: {frame_id: "map"}, 
>     pose: {pose: {position: {x: 0.0, y: 0.0, z: 0.0}, 
>     orientation: {w: 1.0}}}}'"
> ```

# 2. Real Environment (Fastbot)
Considering this is a fresh pi setup with ubuntu 20.04, docker and optionally humble installed, continue the rest instructions.

## 2.1 Images responsible
These are the images thats supposed to be running mandatorly for bringing up the fastbot
  - `fastbot-ros2-real`       (responsible for drivers lidar, serial motor and camera)
  - `fastbot-ros2-slam-real`  (runs cartographer for mapping by default)
  - `fastbot-remote`          (an optional image thats helps to connect to fastbot remotely)

## 2.2 Pull images
```bash
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-real
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-slam-real
```

## 2.3 🚨 Setting up your Pi
Run `pi_setup.sh` which is present inside `docker` folder. By default, this script considers your Pi's username as `fastbot`. If in case you username is differnet, run the script with your username like this

> [✏️ Note] Please read the logs generated by the `pi_setup.sh` script. Lidar, Arduino and serial motor drivers are installed through this setup.

```bash
cd docker/real/scripts
./pi_setup.sh           # if your username is fastbot
./pi_setup.sh ubuntu    # if your username is ubuntu. But this would need a manual update inside `fastbot.services`
```
You can reboot at this point since all necessary images will be running
![fastbot.service](/docs/images/pi-fastbot-services-status.png)

> [🚨 Important] :
>
> When you login (immediatly after boot), only `fastbot-ros2-real` container will be running. So you can list and view the topics.
> 
> `slam-real` container will **NOT** be running after boot.

![docker info](/docs/images/pi-docker-info.png)

## 2.4 Compose types:
> [Note] switch to respective directory `cd ~/ros2_ws/src/docker/real` before bringing up any 

  - local
    - robot -> `fastbot-ros2-real` **(Default running service on fastbot during boot)**
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


# 3. Connect to Fastbot Locally
Connet to your fastbot over `ssh`. If you are about to open graphical tool(Rviz or other ros rqt tools) better start ssh like this `ssh fastbot@192.168.1.100 -C -X` or  `ssh fastbot@192.168.1.100 -C -Y`

### ► pre-req
By default the fastbot will be running just the essential(camera, lidar and serial motor drivers). To start **`slam-real`** or establish a remote connection, bring the default running service down first

```bash
sudo systemctl stop fastbot.service
```
> [⚠️ WARNING]: To avoid stale containers its better to bring container down completely. Because the `fastbot.service` just `stop`'s the container and does not `down`'s the container completely, so that during shutdown, `<container> stop` is quicker that `<container> down`. Recomended to follow the below steps.
```bash
cd docker/real # make sure you switch to docker files path
# list out running containers
docker-compose ps
#bring the default down
docker-compose -f docker-compose.yaml down
```
[ back to [Connect to Fastbot Remotely](#4-connect-to-fastbot-remotely-husarnet)]

### ► Through host (Pi)
Make sure the `real` and `slam-real` are up and running _(after boot it will be running only `robot` in `fastbot.service` automatically)_.

No additional changes needed, fastbot nodes will be visible directly on the host.
```bash
ros2 topic list # directly on pi / host
```
![pi-host-topics](/docs/images/pi-host-topic-list.png)
If its still not visible set the env variables and try (follow the below steps)
```bash
# On Pi host — match the container's env variable
export ROS_DOMAIN_ID=0

ros2 topic list

ros2 daemon stop #(optional if topics still not visible, then procede with topic listing)
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp # add it for future remote connection useage
```


### ► Through Container
```bash
docker exec -it fastbot-ros2-real bash -c "source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash && 
  ros2 topic list"
```
[ Check [expected output](#expected-topics-when-fastbot-container-not-running) ]

## 3.1 Visualize
### ► from fastbot / host(Pi)
> [NOTE] : The running container **`real` and `slam-real` are base images without gui**. So you will be forced to use local host(Pi/fastbot) or even from remote to visualize.

```bash
# Make sure `real` and `slam-real` running
rviz2 -d ~/ros2_ws/src/fastbot_slam/rviz/default.rviz 
```
![topics-rviz](/docs/images/pi-rviz-from-host.png)

## 3.2 Maps
### 3.2.1 Create a new Map
Make sure `real` and `slam-real` container are running on the Fastbot.
#### ► Through host / container on host
The `real` and `slam-real` image are not full desktop or gui based. 
Instead you can run `rviz2` on the fastbot(host) directly while `real` and `slam-real` are running. Look at the section visualize through host. Once you can see the topics of fastbot, you can directly fire up `rviz2` on the host (if installed) to visualize.

```bash
# bring up rviz saved config from the repo in not running
rviz2 -d ~/ros2_ws/src/fastbot_slam/rviz/default.rviz

# If you can view topics directly from host
ros2 run teleop_twist_keyboard teleop_twist_keyboard   --ros-args --remap cmd_vel:=fastbot/cmd_vel
#                   Or
# If you cannot view topics from host , run the same through container
docker exec -it fastbot-ros2-slam-real bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args --remap cmd_vel:=fastbot/cmd_vel"
```

### 3.2.2 Save map to volume space
```bash
docker exec -it fastbot-ros2-slam-real bash -c \
"source /opt/ros/humble/setup.bash &&
 source /ros2_ws/install/setup.bash &&
 ros2 run nav2_map_server map_saver_cli \
  -f /maps/my_map \
  --ros-args -p save_map_timeout:=5.0"
```

### 3.2.3 Load saved map from volume space
```bash
# Quick check to list maps under volume space
docker exec -it fastbot-ros2-slam bash -c \
"ls -la /maps/"

SLAM_MODE=localization MAP_NAME=my_map MAP_FILE=/maps/my_map.yaml \
  docker-compose up -d
```

# 4. Connect to Fastbot Remotely (Husarnet)
## ► pre-req
Ref [earlier Pre-req](#-pre-req)

## 4.1 Bring up the Remote connect on the Fastbot(Pi)
The connection is established through Husarnet and all necessary setups are done through  `docker-compose.husarnet.yaml`

```bash
cd docker/real
docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml up -d

# To bring it down
docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml down -d
```

## 4.2 Setup & Connect Remote Container on Remote Machine
Pre-req: You need to have `docker` installed atleas to pull the image

## ► Pull image
```bash
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-remote
```

## ► Build Remote image (Optional)
```bash
docker build -f docker/real/Dockerfile.remote \
  -t tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-remote .
```
## ► Run the container
```bash
cd docker/real/
docker compose -f docker-compose.remote.yaml up -d

# To bring it down
docker compose -f docker-compose.remote.yaml down -d
```


## 4.3 View / Visualize fastbot through Remote Container
Check for topics availability on 
### 1. Remote Container
```bash
# List topics through remote container
docker exec -it fastbot-remote bash -c "source /opt/ros/humble/setup.bash && 
  ros2 topic list"

# Fire up Rviz throug remote container
docker exec -it fastbot-remote bash -c \
  "source /opt/ros/humble/setup.bash && rviz2 -d /ros2_ws/rviz/default.rviz"
```

### 2. Remote host
> [📢 Important] This needs husarnet to be installed and configured, along with ros2 humble, cyclonedds_cpp

This step needs ros2 installed on your local machine(remote w.r.t fastbot)
if so check for `ROS_DOMAIN_ID`. Our container are set to `0`, if your local is different, set it to `0`. Then you shoudl see fastbots topic.

```bash
ros2 topic list
```

If not visible, copy the `cyclonedds-husarnet.xml` from `docker/real/condif` and place it in you home path, then export the following env variables.
> [!NOTE]: your device need to be added to husarnet dashboard for this step.

```bash
# Set ROS environment on your remote machine
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp  # Installation required
export ROS_DOMAIN_ID=0
# This step needs a manual copy from of `docker/real/config/cyclonedds-husarnet.xml` from the repo to your home user path.
export CYCLONEDDS_URI=file:///home/USER/cyclonedds-husarnet.xml

# Verify Husarnet is connected
husarnet status

# List topics from Pi
ros2 topic list

# Run RViz
rviz2
```
Without setting CYCLONEDDS_URI on the host, it uses default multicast while containers use Husarnet unicast — they're on different DDS networks and can't see each other.

So when running husarnet compose, set the same CYCLONEDDS_URI on the Pi host too — then both host and external machine see all topics.

## 4.4 Maps
#### ► Create a new Map
Make sure `real` and `slam-real` container are running on the Fastbot.
#### ► Through host / container on host
The `real` and `slam-real` image are not full desktop or gui based. 
Instead you can run `rviz2` on the fastbot(host) directly while `real` and `slam-real` are running. Look at the section visualize through host, [follow this](#visualize-from-fastbot--hostpi). Once you can see the topics of fastbot, you can directly fire up `rviz2` on the host (if installed) to visualize.

```bash
# List topics
docker exec -it fastbot-ros2-real bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 topic list"

# Fire up rviz saved config from the repo
rviz2 -d ~/ros2_ws/src/fastbot_slam/rviz/default.rviz 

# Control through Teleop
docker exec -it fastbot-ros2-real bash -c \
  "source /ros2_ws/install/setup.bash && \
  ros2 run teleop_twist_keyboard teleop_twist_keyboard \
  --ros-args --remap cmd_vel:=fastbot/cmd_vel"

# Or you can even control throug webpage if you are running this remote container from the rosject
```
![map creation through remote container](/docs/images/pi-map-creation.png)

# 5. Help yourself

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
[ back to [Load maps from volumes](#-from-volume) ]

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
[ back to [viewing topics](#15-view-topics) ]

[ back to [Remote connection](#connect-to-fastbot-locally) ]