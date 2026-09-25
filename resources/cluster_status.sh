#!/usr/bin/env bash

set -euo pipefail

job_id="${1:-}"

if [[ -z "${job_id}" ]]; then
  echo "failed"
  exit 0
fi

state=$(sacct -X -j "${job_id}" -n -P --format=State 2>/dev/null | awk 'NF {print; exit}')
state=${state%% *}

if [[ -z "${state}" ]]; then
  # sacct can briefly lag behind submission; treat unknown-new jobs as running
  # to avoid false failures immediately after launch.
  echo "running"
  exit 0
fi

case "${state}" in
  COMPLETED)
    echo "success"
    ;;
  PENDING|CONFIGURING|RUNNING|COMPLETING|SUSPENDED|RESIZING|REQUEUED|REQUEUE_HOLD)
    echo "running"
    ;;
  FAILED|CANCELLED|TIMEOUT|OUT_OF_MEMORY|NODE_FAIL|PREEMPTED|BOOT_FAIL|DEADLINE|*)
    echo "failed"
    ;;
esac
