#!/usr/bin/env bash
set -euo pipefail

# check-cmux-health.sh — Claude Code + cmux 연속 개발 환경 건강 체크
# Exit codes:
#   0  fully healthy — cl 바로 실행 가능
#   10 fallback-ready — cmux 불가, 일반 터미널에서 CL_NO_TMUX=1 cl 사용
#   20 claude unhealthy — claude CLI 자체가 실행 불가

CMUX_SOCKET_DEFAULT="${HOME}/Library/Application Support/cmux/cmux.sock"
CMUX_SOCKET_PATH_EFFECTIVE="${CMUX_SOCKET_PATH:-${CMUX_SOCKET_DEFAULT}}"
OVERALL_STATUS=0
STATUS_FULLY_HEALTHY=0
STATUS_FALLBACK_READY=10
STATUS_CLAUDE_UNHEALTHY=20

section() {
  printf '\n== %s ==\n' "$1"
}

note() {
  printf '%s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

mark_failure() {
  OVERALL_STATUS="${STATUS_CLAUDE_UNHEALTHY}"
  warn "$1"
}

mark_fallback_ready() {
  if [[ "${OVERALL_STATUS}" -lt "${STATUS_CLAUDE_UNHEALTHY}" ]]; then
    OVERALL_STATUS="${STATUS_FALLBACK_READY}"
  fi
  warn "$1"
}

run_and_print() {
  local label="$1"
  shift
  local output
  local rc

  printf '$ %s\n' "${label}"
  set +e
  output="$("$@" 2>&1)"
  rc=$?
  set -e

  if [[ -n "${output}" ]]; then
    printf '%s\n' "${output}"
  fi

  return "${rc}"
}

section "Shell"
note "pwd: $(pwd)"
note "shell: ${SHELL:-unknown}"
note "tmux: ${TMUX:-inactive}"
note "cmux workspace env: ${CMUX_WORKSPACE_ID:-unset}"
note "cmux surface env: ${CMUX_SURFACE_ID:-unset}"

section "Claude Code"
if run_and_print "which claude" which claude; then
  :
else
  mark_failure "claude is not on PATH."
fi

if run_and_print "claude --version" claude --version; then
  :
else
  mark_failure "claude CLI did not return version output successfully."
fi

# Check that cl shell function is available in interactive zsh
if zsh -i -c 'type cl >/dev/null 2>&1'; then
  note "cl function: loaded from ~/.zshrc"
else
  mark_fallback_ready "cl function is not loaded. Re-run install-shell-integration.sh and 'source ~/.zshrc'."
fi

section "Project"
if [[ -f ".claude/project-profile.md" ]]; then
  note "project-profile: present"
  grep -E '^(blueprint|last_machine|last_session):' .claude/project-profile.md 2>/dev/null || true
elif [[ -d ".claude" ]]; then
  note "project-profile: missing (run init-project.sh)"
else
  note "project-profile: not initialized (run init-project.sh)"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  local_branch="$(git branch --show-current 2>/dev/null)"
  dirty_count="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  note "git branch: ${local_branch:-(detached)}"
  note "git dirty: ${dirty_count} files"
else
  note "git: not a git repository"
fi

section "CMUX"
note "socket: ${CMUX_SOCKET_PATH_EFFECTIVE}"
if ! command -v cmux >/dev/null 2>&1; then
  mark_fallback_ready "cmux command is not available on PATH. Falling back to normal-terminal cl is allowed."
else
  if run_and_print "cmux ping" cmux ping; then
    note "cmux control plane responded."
    run_and_print "cmux list-workspaces" cmux list-workspaces || mark_fallback_ready "cmux list-workspaces failed after a successful ping. Normal-terminal cl fallback is allowed."
  else
    mark_fallback_ready "cmux socket or daemon is unavailable. Normal-terminal cl fallback is allowed."
  fi
fi

section "Next Step"
if [[ "${OVERALL_STATUS}" -eq "${STATUS_FULLY_HEALTHY}" ]]; then
  note "Healthy. Continue with:"
  note "  cl \"작업 내용\"         # tmux 자동 래핑 + claude 실행"
  note "  cl \"작업 내용\"                       # 해당 경로의 기존 세션 재접속"
  note "  tmux list-sessions | grep '^cl-'       # 세션 이름 확인 후 수동 재접속"
elif [[ "${OVERALL_STATUS}" -eq "${STATUS_FALLBACK_READY}" ]]; then
  note "Fallback-ready. Use one of:"
  note "  1. 같은 Mac 일반 터미널: CL_NO_TMUX=1 cl \"작업 내용\""
  note "  2. 다른 Mac에서: sync-current-branch.sh && cl \"작업 내용\""
  note "  3. cmux 복구 후: ./scripts/check-cmux-health.sh"
else
  note "Claude Code 자체가 unhealthy. 다음을 시도:"
  note "  1. which claude 로 PATH 확인"
  note "  2. install-shell-integration.sh 재실행"
  note "  3. source ~/.zshrc"
  note "  4. ./scripts/check-cmux-health.sh 재실행"
fi

exit "${OVERALL_STATUS}"
