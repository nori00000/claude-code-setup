#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REMOTE_SHELL="zsh"
MAIN_MAC_HOST_VALUE="${MAIN_MAC_HOST:-}"
PROJECT_PATH_VALUE="${MAIN_MAC_PROJECT_PATH:-}"
PRINT_ONLY=0
REMOTE_CMD_VALUE=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ssh-main-mac-project.sh [--host HOST] [--project PATH] [--cmd COMMAND] [--print]

Purpose:
  SSH into the main Mac, change into the project directory, and either open a login shell or run follow-up commands there.

Inputs:
  --host HOST       SSH host alias or destination. Falls back to MAIN_MAC_HOST.
  --project PATH    Project path on the main Mac. Falls back to MAIN_MAC_PROJECT_PATH.
  --cmd COMMAND     Command to run on the main Mac after changing into the project directory.
  --print           Print the resolved ssh command instead of executing it.
  -h, --help        Show this help.

Examples:
  MAIN_MAC_HOST=m4-studio ./scripts/ssh-main-mac-project.sh --project ~/project-a
  MAIN_MAC_HOST=m4-studio ./scripts/ssh-main-mac-project.sh --project /Users/leesangmin/project-a --cmd './scripts/check-cmux-health.sh && omx status && omx resume'
  ./scripts/ssh-main-mac-project.sh --host m4-studio --project /Users/leesangmin/project-a --print
EOF
}

shell_quote() {
  local value="$1"
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

require_value() {
  local flag="$1"
  local value="${2:-}"
  if [[ -z "${value}" ]]; then
    echo "Error: ${flag} requires a value." >&2
    usage >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      require_value "$1" "${2:-}"
      MAIN_MAC_HOST_VALUE="${2:-}"
      shift 2
      ;;
    --project)
      require_value "$1" "${2:-}"
      PROJECT_PATH_VALUE="${2:-}"
      shift 2
      ;;
    --cmd)
      require_value "$1" "${2:-}"
      REMOTE_CMD_VALUE="${2:-}"
      shift 2
      ;;
    --print)
      PRINT_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${MAIN_MAC_HOST_VALUE}" ]]; then
  echo "Error: main Mac host is required. Set MAIN_MAC_HOST or pass --host." >&2
  exit 1
fi

if [[ -z "${PROJECT_PATH_VALUE}" ]]; then
  echo "Error: project path is required. Set MAIN_MAC_PROJECT_PATH or pass --project." >&2
  exit 1
fi

REMOTE_COMMAND="cd $(shell_quote "${PROJECT_PATH_VALUE}")"
if [[ -n "${REMOTE_CMD_VALUE}" ]]; then
  REMOTE_COMMAND="${REMOTE_COMMAND} && exec ${DEFAULT_REMOTE_SHELL} -lc $(shell_quote "${REMOTE_CMD_VALUE}")"
else
  REMOTE_COMMAND="${REMOTE_COMMAND} && exec ${DEFAULT_REMOTE_SHELL} -l"
fi

if [[ "${PRINT_ONLY}" -eq 1 ]]; then
  printf 'ssh %s %s\n' "${MAIN_MAC_HOST_VALUE}" "$(shell_quote "${REMOTE_COMMAND}")"
  exit 0
fi

exec ssh "${MAIN_MAC_HOST_VALUE}" "${REMOTE_COMMAND}"
