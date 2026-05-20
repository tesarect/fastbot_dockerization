# FastBot ROS2 — Docker Deployment

A fully Dockerised ROS 2 Humble workspace for **FastBot**, a differential-drive robot equipped with an LSlidar N10 lidar, a Raspberry Pi camera, and an Arduino Nano motor controller.

The same ROS packages are delivered as Docker images for two targets: a desktop simulation and a Raspberry Pi real robot, with optional remote access over a Husarnet VPN.

---

## What is achieved

### Simulation (desktop / TheConstruct)
Three images bring up a complete simulation pipeline on any x86 machine:

| Image | Role |
|---|---|
| `fastbot-ros2-gazebo` | Gazebo simulation world + robot |
| `fastbot-ros2-slam` | Cartographer mapping + Nav2 navigation |
| `fastbot-ros2-webapp` | Web control panel (joystick, map view, camera) |

- Mapping and navigation modes switchable via environment variables — no compose file edits needed.
- Maps persist in a named Docker volume (`fastbot-maps`) and can be saved, loaded, or swapped at runtime.
- Web interface accessible from TheConstruct's public URL or `localhost`.

### Real Robot (Raspberry Pi — ARM64)
Two images run the full robot stack on the Pi:

| Image | Role |
|---|---|
| `fastbot-ros2-real` | Lidar driver, camera, serial motor controller |
| `fastbot-ros2-slam-real` | Cartographer mapping (real sensor data) |

- Pi host setup is automated by `docker/pi_setup.sh` (udev rules, Docker install, camera config, systemd service).
- `fastbot.service` auto-starts the robot container on every boot; accepts a username argument for non-default Pi users.
- Maps saved to a persistent volume (`fastbot-maps-real`).

### Remote Access (PC → Pi over Husarnet)
A third image runs on the remote laptop to bridge into the robot's DDS network:

| Image | Role |
|---|---|
| `fastbot-ros2-remote` | RViz2 + ROSBridge + Web Video Server over Husarnet VPN |

- RViz launches with the pre-loaded `default.rviz` config from `fastbot_slam`.
- CycloneDDS is configured for Husarnet unicast — no multicast leakage.

---

## Repository layout

```
fastbot_dockerization/
├── docker/
│   ├── real/                  ← real-robot Dockerfiles, compose files, CycloneDDS profiles
│   │   ├── Dockerfile.real
│   │   ├── Dockerfile.slam-real
│   │   ├── Dockerfile.remote
│   │   ├── docker-compose.yaml
│   │   ├── docker-compose.husarnet.yaml
│   │   ├── docker-compose.remote.yaml
│   │   └── scripts/
│   │       ├── fastbot.service    ← systemd unit for auto-start on Pi boot
│   │       └── pi_setup.sh        ← one-shot Pi host setup script
│   ├── simulation/            ← simulation Dockerfiles and compose files
│   ├── Instructions.md        ← full step-by-step instructions and commands
│   └── pi_setup.sh            ← Pi setup entry point
├── fastbot_bringup/           ← real-robot orchestration launch
├── fastbot_description/       ← URDF/xacro + robot_state_publisher
├── fastbot_gazebo/            ← simulation worlds and launch files
├── fastbot_slam/              ← Cartographer/Nav2 configs, launch files, saved maps
├── serial_motor/              ← Arduino motor driver (pyserial)
└── Lslidar_ROS2_driver/       ← LSlidar N10 driver
```

---

## Images

All images are published to Docker Hub under:

```
tesarect/karthikeyanbalasubramanian-cp22:<tag>
```

| Tag | Target |
|---|---|
| `fastbot-ros2-gazebo` | Simulation — Gazebo |
| `fastbot-ros2-slam` | Simulation — SLAM + Nav2 |
| `fastbot-ros2-webapp` | Simulation — Web control panel |
| `fastbot-ros2-real` | Real robot — drivers (ARM64) |
| `fastbot-ros2-slam-real` | Real robot — Cartographer (ARM64) |
| `fastbot-ros2-remote` | Laptop — remote RViz + ROSBridge |

---

## Instructions

All setup steps, build commands, compose invocations, and troubleshooting are documented in:

**[docker/Instructions.md](docker/Instructions.md)**

This covers:
- TheConstruct / local machine prerequisites
- Building or pulling images
- Running simulation (mapping and navigation modes)
- Pi host setup (`pi_setup.sh`)
- Bringing up the real robot
- Establishing remote access over Husarnet
- Map creation, saving, and loading
- Logs, volume inspection, and common diagnostics
