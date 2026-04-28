# SLAM Toolbox Run

## Introduction

This package provides launch files and configurations for SLAM Toolbox, enabling real-time SLAM (Simultaneous Localization and Mapping) based on 2D LiDAR.

## Features

**Supported:**
- Asynchronous online mapping mode (`async_slam_toolbox_node`)
- Synchronous online mapping mode (`sync_slam_toolbox_node`)
- 2D LiDAR data input
- Real-time occupancy grid map generation

**Not Supported:**
- 3D SLAM
- Localization-only mode (requires additional configuration)

## Quick Start

### Prerequisites

- ROS 2 Humble
- `slam_toolbox` package installed
- 2D LiDAR device or simulation environment

**Required Topics:**

| Topic | Type | Description |
|-------|------|-------------|
| `/scan` | sensor_msgs/LaserScan | 2D laser scan data |

**Required TF:**
- `odom` -> `base_footprint`

### Build

```bash
colcon build --packages-select slam_toolbox_run
source install/setup.bash
```

### Run Examples

**Asynchronous Mode (Recommended):**
```bash
ros2 launch slam_toolbox_run online_async_launch.py
```

**Synchronous Mode:**
```bash
ros2 launch slam_toolbox_run online_sync.launch.py
```

**Published Topics:**

| Topic | Type | Description |
|-------|------|-------------|
| `/map` | nav_msgs/OccupancyGrid | Occupancy grid map |
| `/map_metadata` | nav_msgs/MapMetaData | Map metadata |

## Detailed Usage

Configuration files are located in the `config/` directory:
- `mapper_params_online_async.yaml` - Parameters for async mode
- `mapper_params_online_sync.yaml` - Parameters for sync mode

For more details, please refer to the [SLAM Toolbox Official Documentation](https://github.com/SteveMacenski/slam_toolbox).

## FAQ

**Q: Map is not being generated?**
A: Check if the `/scan` topic is being published correctly, and ensure the TF tree is complete (`odom` -> `base_footprint`).

**Q: How to choose between async and sync mode?**
A: Async mode offers better performance and is suitable for most scenarios; sync mode is suitable for scenarios requiring strict time synchronization.

## Version & Release

| Version | Date | Description |
|---------|------|-------------|
| 0.0.1 | 2026-02 | Initial release |

## Contributing

Issues and Pull Requests are welcome.

## License

The source code files in this component are declared as Apache-2.0. The final license is subject to the `LICENSE` file in this directory.
