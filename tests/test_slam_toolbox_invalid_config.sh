#!/usr/bin/env bash
#
# Copyright (C) 2026 SpacemiT (Hangzhou) Technology Co. Ltd.
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

module_dir="${SROBOTIS_ROOT:-$(pwd)}/middleware/ros2/slam/slam_toolbox_run"
artifact_dir="${SROBOTIS_TEST_ARTIFACT_DIR:-${module_dir}/test-artifacts/slam-toolbox-invalid-config}"
log_dir="${artifact_dir}/logs"
log_file="${log_dir}/slam_toolbox_invalid_config.log"
launch_log_file="${log_dir}/slam_toolbox_invalid_config.launch.log"
ros_log_dir="${artifact_dir}/ros_logs"
invalid_config="${artifact_dir}/invalid_mapper_params.yaml"
invalid_config_pattern="(Failed to parse global arguments|Couldn't parse parameter override rule|Error opening YAML file|invalid_mapper_params\.yaml|parser error|yaml)"

mkdir -p "${log_dir}" "${ros_log_dir}"
: >"${log_file}"
: >"${launch_log_file}"

trap 'set +e
if [[ -n "${launch_pid:-}" ]]; then
  kill -- "-${launch_pid}" >/dev/null 2>&1 || kill "${launch_pid}" >/dev/null 2>&1 || true
  wait "${launch_pid}" >/dev/null 2>&1 || true
fi' EXIT

log() {
  echo "[slam-toolbox-invalid-config] $*" | tee -a "${log_file}"
}

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
export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-45}"
export PYTHONUNBUFFERED=1

if ! command -v ros2 >/dev/null 2>&1; then
  log "ERROR: ros2 command not found"
  exit 1
fi

if ! ros2 pkg prefix slam_toolbox >/dev/null 2>&1; then
  log "ERROR: required ROS package slam_toolbox not found; install package.xml system dependencies before running tests."
  exit 1
fi

cat >"${invalid_config}" <<'YAML'
slam_toolbox:
  ros__parameters:
    scan_topic: [/scan
YAML

log "Verifying slam_toolbox fails for invalid YAML parameter file ${invalid_config}"
setsid ros2 run slam_toolbox async_slam_toolbox_node --ros-args --params-file "${invalid_config}" \
  >>"${launch_log_file}" 2>&1 &
launch_pid=$!

deadline=$((SECONDS + 20))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  if grep -Eqi "${invalid_config_pattern}" "${launch_log_file}"; then
    cat "${launch_log_file}" >>"${log_file}"
    log "Observed expected invalid configuration error."
    log "SLAM TOOLBOX INVALID CONFIG TEST PASSED."
    exit 0
  fi

  if ! kill -0 "${launch_pid}" >/dev/null 2>&1; then
    if wait "${launch_pid}"; then
      log "ERROR: slam_toolbox unexpectedly succeeded for invalid configuration"
      tee -a "${log_file}" <"${launch_log_file}" >&2
      exit 1
    fi

    cat "${launch_log_file}" >>"${log_file}"
    if grep -Eqi "${invalid_config_pattern}" "${launch_log_file}"; then
      log "Observed expected invalid configuration error."
      log "SLAM TOOLBOX INVALID CONFIG TEST PASSED."
      exit 0
    fi
    break
  fi

  sleep 0.5
done

log "ERROR: did not observe the expected invalid configuration error within 20s"
tee -a "${log_file}" <"${launch_log_file}" >&2
exit 1