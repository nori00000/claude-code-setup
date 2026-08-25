#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-codex-companion.sh

Delegates Codex auto-resume/session-watcher installation to dev-retrospective.

Resolution order:
  1. $DEV_RETRO_ROOT
  2. ~/projects/dev-retrospective
  3. ~/.dev-retrospective
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

find_dev_retro() {
  local candidate
  for candidate in \
    "${DEV_RETRO_ROOT:-}" \
    "${HOME}/projects/dev-retrospective" \
    "${HOME}/.dev-retrospective"
  do
    [[ -n "${candidate}" ]] || continue
    if [[ -f "${candidate}/scripts/setup-codex-logger.sh" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

DEV_RETRO="$(find_dev_retro || true)"

if [[ -z "${DEV_RETRO}" ]]; then
  cat >&2 <<'EOF'
dev-retrospective not found.

Install it first, then rerun:
  git clone git@github.com:nori00000/dev-retrospective.git ~/projects/dev-retrospective
  bash ~/projects/dev-retrospective/scripts/setup-machine.sh

Or set DEV_RETRO_ROOT to an existing dev-retrospective checkout.
EOF
  exit 1
fi

echo "[codex-companion] using dev-retrospective at: ${DEV_RETRO}"
echo "[codex-companion] delegating to: ${DEV_RETRO}/scripts/setup-codex-logger.sh"

bash "${DEV_RETRO}/scripts/setup-codex-logger.sh"
