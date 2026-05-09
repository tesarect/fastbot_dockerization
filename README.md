# FastBot ROS2 Docker — Simulation

## Project Structure

```
fastbot_ros2_docker/          ← build context (always run docker build from here)
├── simulation/
│   ├── Dockerfile.gazebo     ← Gazebo simulation image
│   ├── Dockerfile.slam       ← SLAM + Navigation image (cartographer + nav2)
│   ├── Dockerfile.web        ← Web control panel image
│   ├── docker-compose.yaml   ← base service definitions
│   ├── docker-compose.prod.yaml ← production overrides (X11, healthchecks, limits)
│   ├── scripts/
│   │   ├── entrypoint.sh         ← shared ROS 2 entrypoint
│   │   └── start_web_services.sh ← webapp startup script
│   └── README.md
├── real/                     ← real robot Docker files (Task 2)
├── fastbot_description/      ← robot URDF/xacro (shared by all images)
├── fastbot_gazebo/           ← simulation worlds and launch files
├── fastbot_slam/             ← cartographer + nav2 launch files and maps
├── fastbot_webapp/           ← web control panel (add when ready)
└── tf2_web_republisher_py/   ← TF2 republisher for roslibjs
```

## Initial Setup

### 1. Clone this repository
```bash
git clone https://github.com/<your_username>/fastbot_ros2_docker.git
cd fastbot_ros2_docker
```

### 2. Docker Hub login
```bash
docker login
```

## Building Images

Always run `docker build` from the **project root** (`fastbot_ros2_docker/`):

```bash
docker build -f simulation/Dockerfile.gazebo -t <username>-cp22:fastbot-ros2-gazebo .
docker build -f simulation/Dockerfile.slam   -t <username>-cp22:fastbot-ros2-slam .
docker build -f simulation/Dockerfile.web    -t <username>-cp22:fastbot-ros2-webapp .
```

## Running the Simulation

### Mapping mode (default — creates a map using Cartographer)
```bash
# Allow X11 forwarding for Gazebo GUI
xhost +local:docker

cd simulation
docker compose -f docker-compose.yaml -f docker-compose.prod.yaml up
```

### Navigation mode (map already saved — uses AMCL + Nav2)
Edit `docker-compose.yaml` slam service command:
```yaml
command: ros2 launch fastbot_slam localization.launch.py
```
Then run compose as above.

## Verify containers are running
```bash
docker ps
```

## Pushing images to Docker Hub
```bash
docker push <username>-cp22:fastbot-ros2-gazebo
docker push <username>-cp22:fastbot-ros2-slam
docker push <username>-cp22:fastbot-ros2-webapp
```

## Pulling images on a new machine
```bash
docker pull <username>-cp22:fastbot-ros2-gazebo
docker pull <username>-cp22:fastbot-ros2-slam
docker pull <username>-cp22:fastbot-ros2-webapp
```
