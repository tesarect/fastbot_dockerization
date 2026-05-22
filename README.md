# FastBot ROS2 — Docker Deployment

A fully Dockerised ROS 2 Humble workspace for **FastBot**, a differential-drive robot equipped with an LSlidar N10 lidar, a Raspberry Pi camera, and an Arduino Nano motor controller.

The same ROS packages are delivered as Docker images for two targets: a desktop simulation and a Raspberry Pi real robot, with optional remote access over a Husarnet VPN.

# FastBot ROS2 — Docker Deployment

All Docker images are published to Docker Hub under:

```
tesarect/karthikeyanbalasubramanian-cp22:<tag>
```

---

## Task 1: Simulation

The simulation Docker files live in **`docker/simulation/`** inside this repository.

| Image tag | Role |
|---|---|
| `fastbot-ros2-gazebo` | Gazebo simulation world + robot |
| `fastbot-ros2-slam` | Cartographer mapping + Nav2 navigation |
| `fastbot-ros2-webapp` | Web control panel (joystick, map view, camera feed) |

- Maps persist in a named Docker volume (`fastbot-maps`).
- Web panel accessible via `webpage_address` on TheConstruct or `http://localhost:7000` locally.


### Clone the repository

```bash
mkdir ~/ros2_ws/src/fastbot_ros2_docker
cd ~/ros2_ws/src/fastbot_ros2_docker
git clone https://github.com/tesarect/fastbot_dockerization.git

```

### Start the simulation containers

```bash
cd docker/simulation
docker-compose up -d
```

> If you have a stale volume from a previous run, answer **y** when Docker asks to continue.

### Verify images and containers are running

```bash
docker images
# Expected output:
REPOSITORY                                   TAG                   
tesarect/karthikeyanbalasubramanian-cp22     fastbot-ros2-gazebo
tesarect/karthikeyanbalasubramanian-cp22     fastbot-ros2-slam
tesarect/karthikeyanbalasubramanian-cp22     fastbot-ros2-webapp
```

```bash
docker ps
# Expected output:
IMAGE                                                    NAMES
tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-gazebo   fastbot-ros2-gazebo
tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-slam     fastbot-ros2-slam
tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-webapp   fastbot-ros2-webapp
```
![docker infos](/docs/images/00-docker-infos.png)

### Verify the Gazebo simulation is running

Open the **Graphical Tools** window if it dosent opens automatically. The Gazebo simulation with the FastBot robot in a room should be visible.

**Rviz** will not open automatically. If you want to visualize
```bash
docker exec -it fastbot-ros2-gazebo bash -c \
  "source install/setup.bash && \
  rviz2 -d src/fastbot_description/rviz/fastbot.rviz"
```

### Access the web interface

```bash
webpage_address    # get the public URL for the web control panel
rosbridge_address  # get the WebSocket URL for connecting the web panel to ROS
```

Open the URL from `webpage_address` in a browser. Enter the `rosbridge_address` value to connect. You should be able to:
- Control the robot with the joystick
- See the map being built in real time

To save a map and open an existing map please follow the steps mentioned under [instruction](/docker/Instructions.md) maps section.


## Task 2: Real Robot

The real-robot Docker files live in **`docker/real/`** inside this repository.

| Image tag | Role |
|---|---|
| `fastbot-ros2-real` | LSlidar N10 driver, Raspberry Pi camera, serial motor controller |
| `fastbot-ros2-slam-real` | Cartographer mapping using real sensor data |

- `fastbot.service` systemd unit auto-starts `fastbot-ros2-real` on every boot.
- Maps saved to a persistent volume (`fastbot-maps-real`).


### On the Fastbot (Raspberry Pi), clone the repository

```bash
mkdir ~/ros2_ws/src/fastbot_ros2_docker
cd ~/ros2_ws/src/fastbot_ros2_docker
git clone https://github.com/tesarect/fastbot_dockerization.git
```

### Run the Pi host setup script (first time only)

```bash
cd docker/real/scripts
./pi_setup.sh       # default Pi username is "fastbot"
```

This installs Docker, udev rules for the Lidar and Arduino, and enables the `fastbot.service` systemd unit for auto-start on boot. **Reboot after this step.**

### Start and verify real-robot containers

```bash
docker images
# Expected output:
REPOSITORY                                   TAG                   
tesarect/karthikeyanbalasubramanian-cp22     fastbot-ros2-gazebo
tesarect/karthikeyanbalasubramanian-cp22     fastbot-ros2-slam
tesarect/karthikeyanbalasubramanian-cp22     fastbot-ros2-webapp
```

```bash
docker ps
# Expected output:
IMAGE                                                    NAMES
tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-gazebo   fastbot-ros2-gazebo
tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-slam     fastbot-ros2-slam
tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-webapp   fastbot-ros2-webapp
```

### Verify robot topics
Directly on host/pi
```bash
ros2 topic list
```
> [Note] if the topics are not visible over host
> ```bash
> export ROS_DOMAIN_ID=0
> ros2 topic list
> ros2 daemon stop    # Optional
> ```

Through container
```bash
docker exec -it fastbot-ros2-real bash -c "source /opt/ros/humble/setup.bash &&
  source /ros2_ws/install/setup.bash && 
  ros2 topic list"
```

Expected topics include:

```
/fastbot/scan          ← laser data
/fastbot/image_raw     ← camera data
/fastbot/cmd_vel       ← velocity commands
```

### Verify auto-start on boot

Reboot the robot. After it powers back on, run `docker ps` — both containers should be running automatically without any manual command.

> **Note:** After boot, only `fastbot-ros2-real` starts automatically via `fastbot.service`. To also bring up `fastbot-ros2-slam-real`, run `docker-compose up` from `docker/real/`.

## Task 3: Connect to Real Robot Remotely
### On your Remote machine
#### Pull and start Remote image
```bash
docker pull tesarect/karthikeyanbalasubramanian-cp22:fastbot-ros2-remote

docker compose -f docker-compose.remote.yaml up -d
```

 Image tag | Role |
|---|---|
| `fastbot-ros2-remote` | Ros humble with Rviz and Husarnet configured |

- `fastbot.service` systemd unit auto-starts `fastbot-ros2-real` on every boot.
- Maps saved to a persistent volume (`fastbot-maps-real`).


### On Fastbot
> [Note] Stop the default running container at the boot, and start the container with husarnet configuration
```bash
# Bring down the default container
cd docker/real
docker-compose down

# Bring up the remote connection container
docker-compose -f docker-compose.yaml -f docker-compose.husarnet.yaml up -d

```

### Verify remote access (from an external computer)

```bash
# List topics through remote container
docker exec -it fastbot-remote bash -c "source /opt/ros/humble/setup.bash && 
  ros2 topic list"

# Fire up Rviz throug remote container
docker exec -it fastbot-remote bash -c \
  "source /opt/ros/humble/setup.bash && rviz2 -d /ros2_ws/rviz/default.rviz"
```

To Connect to the fastbot remote machine as host please follow detailed steps mentioned in [instructions](/docker/Instructions.md)


---

## Repository layout

```
fastbot_ros2_docker/
├── docker/
│   ├── simulation/            ← simulation Dockerfiles + docker-compose.yaml
│   │   ├── Dockerfile.gazebo
│   │   ├── Dockerfile.slam
│   │   ├── Dockerfile.webapp
│   │   └── docker-compose.yaml
│   ├── real/                  ← real-robot Dockerfiles + compose files
│   │   ├── Dockerfile.real
│   │   ├── Dockerfile.slam-real
│   │   ├── Dockerfile.remote
│   │   ├── docker-compose.yaml
│   │   ├── docker-compose.husarnet.yaml
│   │   ├── docker-compose.remote.yaml
│   │   └── scripts/
│   │       ├── fastbot.service    ← systemd unit for auto-start on Pi boot
│   │       └── pi_setup.sh        ← one-shot Pi host setup script
│   └── setup_construct.sh     ← TheConstruct environment setup
├── fastbot_bringup/           ← real-robot orchestration launch files
├── fastbot_description/       ← URDF + robot_state_publisher
├── fastbot_gazebo/            ← Gazebo worlds and launch files
├── fastbot_slam/              ← Cartographer/Nav2 configs, launch files, saved maps
├── serial_motor/              ← serial motor driver (pyserial / Arduino)
└── Lslidar_ROS2_driver/       ← LSlidar N10 ROS 2 driver
```

---
