#!/usr/bin/env bash
set -euo pipefail

REMOTE_NAME="origin"
BRANCH_NAME=""
PRINT_ONLY=0

usage() {
  cat <<'EOF'
Usage:
  ./scripts/sync-current-branch.sh [--branch BRANCH] [--remote REMOTE] [--print]

Purpose:
  Fetch from the remote, switch to the target branch, and pull it with --ff-only.

Inputs:
  --branch BRANCH    Branch to sync. Defaults to the current local branch.
  --remote REMOTE    Remote name. Defaults to origin.
  --print            Print the resolved git commands instead of executing them.
  -h, --help         Show this help.

Examples:
  ./scripts/sync-current-branch.sh
  ./scripts/sync-current-branch.sh --branch feature/cmux-health
  ./scripts/sync-current-branch.sh --remote upstream --branch feature/cmux-health --print
EOF
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
    --branch)
      require_value "$1" "${2:-}"
      BRANCH_NAME="${2:-}"
      shift 2
      ;;
    --remote)
      require_value "$1" "${2:-}"
      REMOTE_NAME="${2:-}"
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

if [[ -z "${BRANCH_NAME}" ]]; then
  BRANCH_NAME="$(git branch --show-current)"
fi

if [[ -z "${BRANCH_NAME}" ]]; then
  echo "Error: unable to detect the current branch. Pass --branch explicitly." >&2
  exit 1
fi

if [[ "${PRINT_ONLY}" -eq 1 ]]; then
  printf 'git fetch %s\n' "${REMOTE_NAME}"
  printf 'git switch %s\n' "${BRANCH_NAME}"
  printf 'git pull --ff-only %s %s\n' "${REMOTE_NAME}" "${BRANCH_NAME}"
  exit 0
fi

git fetch "${REMOTE_NAME}"
git switch "${BRANCH_NAME}"
git pull --ff-only "${REMOTE_NAME}" "${BRANCH_NAME}"
