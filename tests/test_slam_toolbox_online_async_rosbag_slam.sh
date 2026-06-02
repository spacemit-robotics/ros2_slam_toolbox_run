#!/usr/bin/env bash
#
# Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

module_dir="${SROBOTIS_ROOT:-$(pwd)}/middleware/ros2/slam/slam_toolbox_run"
artifact_dir="${SROBOTIS_TEST_ARTIFACT_DIR:-${module_dir}/test-artifacts/slam-toolbox-online-async-rosbag-slam}"
log_dir="${artifact_dir}/logs"
log_file="${log_dir}/slam_toolbox_online_async_rosbag_slam.log"
ros_log_dir="${artifact_dir}/ros_logs"

mkdir -p "${log_dir}" "${ros_log_dir}"
: >"${log_file}"

log() {
  echo "[slam-toolbox-online-async-rosbag-slam] $*" | tee -a "${log_file}"
}

run_logged() {
  log "\$ $*"
  "$@" >>"${log_file}" 2>&1
}

cleanup() {
  set +e
  if [[ -n "${bag_pid:-}" ]]; then
    kill -- "-${bag_pid}" >/dev/null 2>&1 || kill "${bag_pid}" >/dev/null 2>&1 || true
    wait "${bag_pid}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${launch_pid:-}" ]]; then
    kill -- "-${launch_pid}" >/dev/null 2>&1 || kill "${launch_pid}" >/dev/null 2>&1 || true
    wait "${launch_pid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

source_ros_setup() {
  set +u
  if [[ -f "${SROBOTIS_OUTPUT_STAGING:-}/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source "${SROBOTIS_OUTPUT_STAGING}/setup.bash"
  elif [[ -f "${SROBOTIS_ROOT:-$(pwd)}/output/staging/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source "${SROBOTIS_ROOT:-$(pwd)}/output/staging/setup.bash"
  elif [[ -f "${SROBOTIS_ROOT:-$(pwd)}/install/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source "${SROBOTIS_ROOT:-$(pwd)}/install/setup.bash"
  elif [[ -f "/opt/ros/humble/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source "/opt/ros/humble/setup.bash"
  fi
  set -u
}

source_ros_setup

export ROS_LOG_DIR="${ros_log_dir}"
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-44}"
export PYTHONUNBUFFERED=1

bag_dir="${module_dir}/tests/slam_toolbox_test_data"
if [[ ! -f "${bag_dir}/metadata.yaml" ]]; then
  log "ERROR: missing rosbag metadata: ${bag_dir}/metadata.yaml"
  exit 1
fi

if ! command -v ros2 >/dev/null 2>&1; then
  log "ERROR: ros2 command not found"
  exit 1
fi

if ! ros2 pkg prefix slam_toolbox >/dev/null 2>&1; then
  log "ERROR: required ROS package slam_toolbox not found; install package.xml system dependencies before running tests."
  exit 1
fi

if ! ros2 bag --help >/dev/null 2>&1; then
  log "ERROR: required ros2 bag command not found; install package.xml system dependencies before running tests."
  exit 1
fi

if ! python3 -c 'import rclpy; from nav_msgs.msg import OccupancyGrid' >/dev/null 2>&1; then
  log "ERROR: required ROS Python modules rclpy/nav_msgs not found; install package.xml system dependencies before running tests."
  exit 1
fi

run_logged ros2 pkg prefix slam_toolbox_run
run_logged ros2 pkg prefix slam_toolbox

log "Starting online_async_launch.py"
setsid ros2 launch slam_toolbox_run online_async_launch.py >>"${log_file}" 2>&1 &
launch_pid=$!

sleep 4
if ! kill -0 "${launch_pid}" >/dev/null 2>&1; then
  log "ERROR: launch process exited before bag replay"
  exit 1
fi

log "Starting rosbag replay from ${bag_dir}"
setsid ros2 bag play "${bag_dir}" --rate 1.0 >>"${log_file}" 2>&1 &
bag_pid=$!

log "Waiting for a non-empty /map occupancy grid"
python3 - <<'PY' 2>&1 | tee -a "${log_file}"
import math
import os
import sys
import time

import rclpy
from nav_msgs.msg import OccupancyGrid

received = []

def on_map(msg: OccupancyGrid) -> None:
    width = msg.info.width
    height = msg.info.height
    known = sum(1 for value in msg.data if value >= 0)
    print(f"observed /map: width={width} height={height} known_cells={known}", flush=True)
    if width > 0 and height > 0 and known > 0 and math.isfinite(msg.info.resolution):
        received.append((width, height, known))

rclpy.init()
node = rclpy.create_node("slam_toolbox_run_ci_map_assertion")
node.create_subscription(OccupancyGrid, "/map", on_map, 10)
end_time = time.monotonic() + float(os.environ.get("SLAM_TOOLBOX_MAP_TIMEOUT", "60"))
try:
    while time.monotonic() < end_time and not received:
        rclpy.spin_once(node, timeout_sec=0.2)
finally:
    node.destroy_node()
    rclpy.shutdown()

if not received:
    print("ERROR: did not receive a non-empty /map occupancy grid", file=sys.stderr)
    sys.exit(1)

width, height, known = received[0]
print(f"PASS: received non-empty /map occupancy grid width={width} height={height} known_cells={known}")
PY

log "SLAM TOOLBOX ONLINE ASYNC ROSBAG SLAM TEST PASSED."