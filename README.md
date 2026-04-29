# SLAM Toolbox Run

## 项目简介

本包提供 SLAM Toolbox 的启动文件和配置，用于实现基于 2D 激光雷达的实时 SLAM（同步定位与建图）功能。

## 功能特性

**支持：**
- 异步在线建图模式（`async_slam_toolbox_node`）
- 同步在线建图模式（`sync_slam_toolbox_node`）
- 2D 激光雷达数据输入
- 实时生成占用栅格地图

**不支持：**
- 3D SLAM
- 纯定位模式（需额外配置）

## 快速开始

### 环境准备

- ROS 2 Humble
- 已安装 `slam_toolbox` 包
- 2D 激光雷达设备或仿真环境

**所需话题：**

| 话题 | 类型 | 描述 |
|------|------|------|
| `/scan` | sensor_msgs/LaserScan | 2D 激光扫描数据 |

**所需 TF：**
- `odom` -> `base_footprint`

### 构建编译

```bash
colcon build --packages-select slam_toolbox_run
source install/setup.bash
```

### 运行示例

**异步模式（推荐）：**
```bash
ros2 launch slam_toolbox_run online_async_launch.py
```

**同步模式：**
```bash
ros2 launch slam_toolbox_run online_sync.launch.py
```

**发布的话题：**

| 话题 | 类型 | 描述 |
|------|------|------|
| `/map` | nav_msgs/OccupancyGrid | 占用栅格地图 |
| `/map_metadata` | nav_msgs/MapMetaData | 地图元数据 |

## 详细使用

配置文件位于 `config/` 目录：
- `mapper_params_online_async.yaml` - 异步模式参数
- `mapper_params_online_sync.yaml` - 同步模式参数

更多详细信息请参考 [SLAM Toolbox 官方文档](https://github.com/SteveMacenski/slam_toolbox)。

## 常见问题

**Q: 地图无法生成？**
A: 检查 `/scan` 话题是否正常发布，以及 TF 树是否完整（`odom` -> `base_footprint`）。

**Q: 异步模式和同步模式如何选择？**
A: 异步模式性能更好，适合大多数场景；同步模式适合需要严格时间同步的场景。

## 版本与发布

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.0.1 | 2026-02 | 初始版本 |

## 贡献方式

欢迎提交 Issue 和 Pull Request。

## License

本组件源码文件头声明为 Apache-2.0，最终以本目录 `LICENSE` 文件为准。
