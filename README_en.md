# SLAM Toolbox Run

## Introduction

This package provides launch files and configurations for SLAM Toolbox, enabling real-time SLAM (Simultaneous Localization and Mapping) based on 2D LiDAR.

## Features

**Supported:**
- Asynchronous online mapping mode (`async_slam_toolbox_node`)
- Synchronous online mapping mode (`sync_slam_toolbox_node`)
- Localization-only mode (`localization_slam_toolbox_node`, loading an existing `.posegraph` map)
- 2D LiDAR data input
- Real-time occupancy grid map generation

**Not Supported:**
- 3D SLAM

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

**Save an Occupancy Grid Map:**

```bash
ros2 run nav2_map_server map_saver_cli -f my_map
```

**Save a Posegraph Map:**

This map is used by localization-only mode. Localization-only mode can replace AMCL to estimate the `map` -> `odom` TF.

```bash
# This generates both .posegraph and .data files
ros2 service call /slam_toolbox/serialize_map slam_toolbox/srv/SerializePoseGraph "{filename: '/home/root/my_map'}"
```

**Localization-only Mode:**
Prepare a `.posegraph` map saved by SLAM Toolbox, then specify the map path with `map_file_name` without the `.posegraph` suffix:

```bash
ros2 launch slam_toolbox_run localization_launch.py map_file_name:=/path/to/saved_map
```

To use a custom localization parameter file, specify `params_file` as well:

```bash
ros2 launch slam_toolbox_run localization_launch.py \
	map_file_name:=/path/to/saved_map \
	params_file:=/path/to/mapper_params_localization.yaml
```

Example: if the map file is `/home/root/my_map.posegraph`, use the following launch argument:

```bash
ros2 launch slam_toolbox_run localization_launch.py map_file_name:=/home/root/my_map
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
- `mapper_params_localization.yaml` - Parameters for localization-only mode

Supported launch arguments of `launch/localization_launch.py`:

| Argument | Default | Description |
|----------|---------|-------------|
| `map_file_name` | None, required | Path to the `.posegraph` map file without the file suffix |
| `params_file` | `config/mapper_params_localization.yaml` | Path to the SLAM Toolbox localization parameter file |

Localization-only mode depends on an existing map and requires the `/scan` topic and the `odom` -> `base_footprint` TF to be published correctly. After startup, the node loads the specified posegraph and publishes the `map` -> `odom` transform for localization.

For more details, please refer to the [SLAM Toolbox Official Documentation](https://github.com/SteveMacenski/slam_toolbox).

## FAQ

**Q: Map is not being generated?**
A: Check if the `/scan` topic is being published correctly, and ensure the TF tree is complete (`odom` -> `base_footprint`).

**Q: How to choose between async and sync mode?**
A: Async mode offers better performance and is suitable for most scenarios; sync mode is suitable for scenarios requiring strict time synchronization.

**Q: Localization-only mode fails to start or reports that the map cannot be found?**
A: Check whether `map_file_name` points to a saved `.posegraph` map, and make sure the argument value does not include the `.posegraph` suffix.

## Version & Release

| Version | Date | Description |
|---------|------|-------------|
| 0.0.1 | 2026-02 | Initial release |

## Contributing

Issues and Pull Requests are welcome.

## License

The source code files in this component are declared as Apache-2.0. The final license is subject to the `LICENSE` file in this directory.
