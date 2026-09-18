#!/usr/bin/env bash
# ccbr_pipeline_logging.sh
#
# Shared structured-logging / pipeline-state-marker / progress-monitor / script-sync
# library for CCBR Snakemake pipeline wrapper scripts (ASPEN, CARLISLE, ...).
#
# STAGING NOTE: this file is being developed/validated inside the ASPEN repo
# (workflow/scripts/) as prep work for Phase B of
# plans_reviews/PLAN_shared_pipeline_logging_library.md. Phase B will move this
# file to ccbr_tools (scripts/ccbr_pipeline_logging.sh), ship it onto PATH via
# `[tool.setuptools] script-files` in pyproject.toml, and have both ASPEN's
# `aspen` and CARLISLE's `carlisle` wrappers `source` it instead of duplicating
# these functions inline. See CCBR/Tools#230, CCBR/ASPEN#143, CCBR/CARLISLE#264.
#
# Required env vars (consumer must set BEFORE sourcing):
#   PIPELINE_NAME       e.g. "ASPEN" or "CARLISLE"
#   PIPELINE_VERSION    e.g. $ASPENVERSION / $PIPELINE_VERSION
#   SNAKEMAKE_LOG_PATH  absolute path snakemake.log will be written to
#                       (ASPEN: "${WORKDIR}/snakemake.log"
#                        CARLISLE: "${WORKDIR}/logs/snakemake.log")
#   PIPELINE_HOME, WORKDIR  already exported by both wrappers

: "${PIPELINE_NAME:?PIPELINE_NAME must be set before sourcing ccbr_pipeline_logging.sh}"
: "${PIPELINE_VERSION:?PIPELINE_VERSION must be set before sourcing ccbr_pipeline_logging.sh}"
: "${SNAKEMAKE_LOG_PATH:?SNAKEMAKE_LOG_PATH must be set before sourcing ccbr_pipeline_logging.sh}"

function log_info()    { echo "INFO  $*"; }
function log_step()    { echo "STEP  $*"; }
function log_ok()      { echo "OK    $*"; }
function log_warn()    { echo "WARN  $*"; }
function log_error()   { echo "ERROR $*"; }
function log_next()    { echo "NEXT  $*"; }
function log_divider() { echo "------------------------------------------------------------------"; }

# Prints a boxed banner: PIPELINE_NAME PIPELINE followed by vVERSION.
# Args: name version (version's leading 'v' is stripped/normalized automatically)
function printbanner() {
  local word="${1^^}"
  local ver="${2#v}"          # strip leading 'v' if the caller included one

  local line1="$word PIPELINE"
  local line2=""
  [[ -n "$ver" ]] && line2="v$ver"

  # inner width = longest content line + 2 spaces padding each side, min 34
  local pad=2
  local content_w=${#line1}
  (( ${#line2} > content_w )) && content_w=${#line2}
  local inner=$(( content_w + pad * 2 ))
  (( inner < 34 )) && inner=34

  # build the horizontal rule
  local rule
  printf -v rule '%*s' "$inner" ''
  rule="${rule// /═}"

  local cyan='\033[1;36m' white='\033[1;97m' grey='\033[0;90m' reset='\033[0m'

  printf "\n${cyan}╔%s╗${reset}\n" "$rule"
  printf "${cyan}║${reset}  ${white}%-*s${reset}${cyan}║${reset}\n" "$(( inner - pad ))" "$line1"
  [[ -n "$line2" ]] && \
    printf "${cyan}║${reset}  ${grey}%-*s${reset}${cyan}║${reset}\n" "$(( inner - pad ))" "$line2"
  printf "${cyan}╚%s╝${reset}${reset}\n\n" "$rule"
}

function print_versions() {
  log_divider
  echo "INFO  Tool Versions:"
  snakemake --version 2>/dev/null && log_ok "Snakemake version checked" || log_warn "Snakemake version: unable to determine"
  singularity --version 2>/dev/null && log_ok "Singularity/Apptainer version checked" || log_warn "Singularity/Apptainer version: UNAVAILABLE"
  log_divider
}

function json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Returns "<git_commit_id>\t<git_tag>" for the given pipeline home directory
# (a git checkout). Args: pipeline_home_dir
function get_git_commitid_tag() {
  local dir="$1"
  local gid tag
  gid=$(git -C "${dir}" rev-parse HEAD)
  tag=$(git -C "${dir}" describe --tags "${gid}" 2>/dev/null)
  echo -ne "${gid}\t${tag}"
}

# Internal helper shared by write_pipeline_state_marker() and
# write_pipeline_state_marker_job() so the JSON sidecar is only assembled in one
# place. Positional args:
#   1=state 2=reason 3=job_id 4=host 5=submission_ts 6=start_ts
#   7=duration_seconds 8=exit_code 9=tasks_done 10=tasks_total
function _pipeline_write_status_json() {
  local state="$1" reason="$2" job_id="$3" host="$4" submission_ts="$5"
  local start_ts="$6" duration_seconds="$7" exit_code="$8" tasks_done="$9" tasks_total="${10}"
  local now_utc sidecar sidecar_tmp start_ts_json

  now_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  sidecar="${WORKDIR}/pipeline.status.json"
  sidecar_tmp="${sidecar}.tmp.$$"

  if [[ -n "${start_ts}" ]]; then
    start_ts_json="\"$(json_escape "${start_ts}")\""
  else
    start_ts_json="null"
  fi

  rm -f "${WORKDIR}/pipeline.running" "${WORKDIR}/pipeline.completed" \
        "${WORKDIR}/pipeline.failed" "${WORKDIR}/pipeline.canceled"
  : > "${WORKDIR}/pipeline.${state}"

  cat > "${sidecar_tmp}" << STATEEOF
{
  "pipeline": "${PIPELINE_NAME}",
  "version": "${PIPELINE_VERSION}",
  "state": "$(json_escape "${state}")",
  "reason": "$(json_escape "${reason}")",
  "runmode": "$(json_escape "${RUNMODE:-unknown}")",
  "workdir": "$(json_escape "${WORKDIR}")",
  "user": "$(json_escape "${USER:-unknown}")",
  "slurm_job_id": "$(json_escape "${job_id}")",
  "host": "$(json_escape "${host}")",
  "submission_timestamp_utc": "$(json_escape "${submission_ts}")",
  "start_timestamp_utc": ${start_ts_json},
  "duration_seconds": ${duration_seconds:-null},
  "exit_code": ${exit_code:-null},
  "tasks_done": ${tasks_done:-null},
  "tasks_total": ${tasks_total:-null},
  "snakemake_log": "$(json_escape "${SNAKEMAKE_LOG_PATH}")",
  "timestamp_utc": "${now_utc}"
}
STATEEOF
  mv "${sidecar_tmp}" "${sidecar}"
}

# Outer (pre-sbatch-submission) marker writer, run on the login/head node before
# the job is submitted. Args: state reason [job_id]
function write_pipeline_state_marker() {
  local state="$1"
  local reason="${2:-}"
  local job_id="${3:-NA}"
  local host submission_ts="" submit_epoch now_utc

  now_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  host=$(hostname 2>/dev/null || echo "unknown")

  if [[ "${state}" == "running" && "${reason}" == "submission_started" ]]; then
    submission_ts="${now_utc}"
    date +%s > "${WORKDIR}/pipeline.submit_epoch"
  elif [[ -f "${WORKDIR}/pipeline.submit_epoch" ]]; then
    submit_epoch=$(cat "${WORKDIR}/pipeline.submit_epoch" 2>/dev/null || true)
    if [[ -n "${submit_epoch}" ]]; then
      submission_ts=$(date -u -d "@${submit_epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || true)
    fi
  fi

  _pipeline_write_status_json "${state}" "${reason}" "${job_id}" "${host}" \
    "${submission_ts}" "" "" "" "" ""
  log_info "State marker updated: pipeline.${state} (reason=${reason}, slurm_job_id=${job_id})"
}

# On-compute-node marker writer, run from inside the generated sbatch submit
# script (after `module load ccbrpipeliner; source ccbr_pipeline_logging.sh`).
# Requires the caller to export _START_EPOCH/_START_TS right after module load.
# Args: state reason [job_id] [exit_code]
function write_pipeline_state_marker_job() {
  local state="$1"
  local reason="${2:-}"
  local job_id="${3:-${SLURM_JOB_ID:-NA}}"
  local exit_code="${4:-}"
  local host submission_ts="" submit_epoch duration_seconds=""
  local tasks_done="" tasks_total="" raw_tasks

  host=$(hostname 2>/dev/null || echo "unknown")

  if [[ -f "${WORKDIR}/pipeline.submit_epoch" ]]; then
    submit_epoch=$(cat "${WORKDIR}/pipeline.submit_epoch" 2>/dev/null || true)
    if [[ -n "${submit_epoch}" ]]; then
      submission_ts=$(date -u -d "@${submit_epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || true)
    fi
  fi

  if [[ -n "${_START_EPOCH:-}" ]]; then
    duration_seconds=$(( $(date +%s) - _START_EPOCH ))
  fi

  raw_tasks=$(grep -oP '[0-9]+ of [0-9]+ steps \([0-9]+%\) done' "${SNAKEMAKE_LOG_PATH}" 2>/dev/null | tail -1 || true)
  if [[ -n "${raw_tasks}" ]]; then
    tasks_done=$(printf '%s' "${raw_tasks}" | grep -oP '^\d+' || true)
    tasks_total=$(printf '%s' "${raw_tasks}" | grep -oP '(?<=of )\d+' || true)
  fi

  _pipeline_write_status_json "${state}" "${reason}" "${job_id}" "${host}" \
    "${submission_ts}" "${_START_TS:-}" "${duration_seconds}" "${exit_code}" \
    "${tasks_done}" "${tasks_total}"
}

# Best-effort jobby summary of the snakemake log. Path is parameterized via
# SNAKEMAKE_LOG_PATH since ASPEN and CARLISLE use different conventions.
function run_jobby_best_effort() {
  local log_dir
  log_dir="$(dirname "${SNAKEMAKE_LOG_PATH}")"
  mkdir -p "${log_dir}"
  if ! command -v jobby >/dev/null 2>&1; then
    module load ccbrpipeliner >/dev/null 2>&1 || true
  fi
  if [[ -f "${SNAKEMAKE_LOG_PATH}" ]] && command -v jobby >/dev/null 2>&1; then
    if ! jobby --tsv "${SNAKEMAKE_LOG_PATH}" | tee "${SNAKEMAKE_LOG_PATH}.jobby" >/dev/null; then
      printf '%s\n' "jobby failed while parsing ${SNAKEMAKE_LOG_PATH}" > "${SNAKEMAKE_LOG_PATH}.jobby"
    fi
  else
    printf '%s\n' "jobby unavailable or snakemake.log missing" > "${SNAKEMAKE_LOG_PATH}.jobby"
  fi
}

# Background loop, started from inside the sbatch submit script right before the
# snakemake invocation (`_progress_monitor & _monitor_pid=$!`), killed/waited on
# right after snakemake exits. Polls SNAKEMAKE_LOG_PATH every 60s, parses
# "N of M steps (P%) done" via grep -oP, and writes a human-readable progress
# summary into "${WORKDIR}/pipeline.running".
function _progress_monitor() {
  local logfile="${SNAKEMAKE_LOG_PATH}"
  local marker="${WORKDIR}/pipeline.running"
  local waited=0
  local max_wait=300
  local raw done_n total_n pct remaining updated

  while [[ ! -f "${logfile}" && "${waited}" -lt "${max_wait}" ]]; do
    [[ -f "${marker}" ]] || return 0
    sleep 10
    waited=$(( waited + 10 ))
  done

  if [[ ! -f "${logfile}" ]]; then
    printf 'Status   : Waiting for snakemake.log\nUpdated  : %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "${marker}"
  fi

  while true; do
    [[ -f "${marker}" ]] || break
    if [[ -f "${logfile}" ]]; then
      raw=$(grep -oP '[0-9]+ of [0-9]+ steps \([0-9]+%\) done' "${logfile}" 2>/dev/null | tail -1 || true)
      if [[ -n "${raw}" ]]; then
        done_n=$(printf '%s' "${raw}" | grep -oP '^\d+' || true)
        total_n=$(printf '%s' "${raw}" | grep -oP '(?<=of )\d+' || true)
        pct=$(printf '%s' "${raw}" | grep -oP '\d+(?=%)' || true)
        if [[ -n "${done_n}" && -n "${total_n}" && -n "${pct}" ]]; then
          remaining=$(( total_n - done_n ))
          (( remaining < 0 )) && remaining=0
          updated=$(date '+%Y-%m-%d %H:%M:%S')
          printf 'Progress : %s / %s steps complete (%s%%)\nRemaining: %s steps\nUpdated  : %s\n' \
            "${done_n}" "${total_n}" "${pct}" "${remaining}" "${updated}" > "${marker}"
        fi
      elif [[ ! -s "${marker}" ]]; then
        printf 'Status   : Submitted, waiting for first progress update\nUpdated  : %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "${marker}"
      fi
    fi
    sleep 60
  done
}

# Generic re-sync of workflow/scripts into WORKDIR/scripts.
# Requires PIPELINE_HOME, WORKDIR already set; caller should define/run its own
# pipeline-specific check_essential_files() before calling this if it wants
# pre-flight validation (this function will call it automatically if it's
# already defined in the caller's shell).
function ccbr_rescript() {
  log_step "[syncscripts] Re-syncing workflow/scripts into workdir"
  if command -v check_essential_files >/dev/null 2>&1; then check_essential_files; fi
  rsync -avz --no-perms --no-owner --no-group --progress --exclude '__pycache__/' \
    "${PIPELINE_HOME}/workflow/scripts/" "${WORKDIR}/scripts/"
  log_ok "${WORKDIR}/scripts has been updated (excluding __pycache__/)."
  log_next "Run dryrun to validate script updates before run/runlocal."
}
