#!/usr/bin/env bash
set -euo pipefail

# init-project.sh — Initialize a project for Claude Code
# Usage: init-project.sh <path-to-project> [--force]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates" && pwd)"
# Sanitize hostname for safe YAML embedding (strip single quotes)
MACHINE_NAME="$(hostname -s 2>/dev/null || echo 'unknown')"
MACHINE_NAME="${MACHINE_NAME//\'/}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <path-to-project> [--force]

Initialize a project directory for Claude Code by creating:
  .claude/manifest.json       — managed-file registry
  .claude/project-profile.md  — filled project profile template

Options:
  --force   Overwrite existing .claude/manifest.json

Notes:
  Run OMC deepinit for AGENTS.md generation.
EOF
  exit 1
}

# ── Argument parsing ─────────────────────────────────────────────────────────
PROJECT_DIR=""
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --help|-h) usage ;;
    -*)
      echo "Unknown option: $arg" >&2
      usage
      ;;
    *)
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$arg"
      else
        echo "Too many arguments." >&2
        usage
      fi
      ;;
  esac
done

[[ -z "$PROJECT_DIR" ]] && usage

# ── Validate project path ────────────────────────────────────────────────────
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: directory does not exist: $PROJECT_DIR" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# ── Detect blueprint ─────────────────────────────────────────────────────────
detect_blueprint() {
  if [[ -f "$PROJECT_DIR/package.json" ]]; then
    echo "web-app"
  elif [[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/setup.py" || -f "$PROJECT_DIR/requirements.txt" ]]; then
    echo "python-service"
  else
    echo "generic"
  fi
}

BLUEPRINT="$(detect_blueprint)"

# ── Detect verification commands ─────────────────────────────────────────────
detect_verification() {
  local install="" fast_check="" full_check=""

  case "$BLUEPRINT" in
    web-app)
      install="npm install"
      if grep -q '"lint"' "$PROJECT_DIR/package.json" 2>/dev/null; then
        fast_check="npm run lint"
      elif grep -q '"type-check"' "$PROJECT_DIR/package.json" 2>/dev/null; then
        fast_check="npm run type-check"
      elif grep -q '"typecheck"' "$PROJECT_DIR/package.json" 2>/dev/null; then
        fast_check="npm run typecheck"
      elif grep -q '"check"' "$PROJECT_DIR/package.json" 2>/dev/null; then
        fast_check="npm run check"
      else
        fast_check="npm test"
      fi
      full_check="npm run build && npm test"
      ;;
    python-service)
      if [[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/setup.py" ]]; then
        install="pip install -e ."
      else
        install="pip install -r requirements.txt"
      fi
      fast_check="python -m pytest -x --tb=short"
      full_check="python -m pytest"
      ;;
    generic)
      install=""
      fast_check=""
      full_check=""
      ;;
  esac

  printf '%s\n%s\n%s\n' "$install" "$fast_check" "$full_check"
}

{
  IFS= read -r INSTALL
  IFS= read -r FAST_CHECK
  IFS= read -r FULL_CHECK
} < <(detect_verification)

# ── Guard against overwrite ───────────────────────────────────────────────────
CLAUDE_DIR="$PROJECT_DIR/.claude"
MANIFEST="$CLAUDE_DIR/manifest.json"

if [[ -f "$MANIFEST" && "$FORCE" == false ]]; then
  echo "Error: $MANIFEST already exists. Use --force to overwrite." >&2
  exit 1
fi

# ── Create .claude/ directory ─────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ── Write manifest.json ───────────────────────────────────────────────────────
CREATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$MANIFEST" <<JSON
{
  "managed_by": "claude-code-setup",
  "blueprint": "$BLUEPRINT",
  "created_at": "$CREATED_AT",
  "updated_at": "$CREATED_AT",
  "managed_files": [
    { "path": ".claude/manifest.json",       "mode": "create" },
    { "path": ".claude/project-profile.md",  "mode": "skip_if_exists" }
  ]
}
JSON

# ── Write project-profile.md (filled from template) ──────────────────────────
PROFILE="$CLAUDE_DIR/project-profile.md"

PROFILE_CREATED=false
if [[ -f "$PROFILE" && "$FORCE" == false ]]; then
  echo "  skipped: $PROFILE (already exists, use --force to overwrite)"
else
PROFILE_CREATED=true
cat > "$PROFILE" <<MARKDOWN
---
# Machine-readable verification commands (consumed by OMC verification module)
verification:
  install: '${INSTALL}'
  fast_check: '${FAST_CHECK}'
  full_check: '${FULL_CHECK}'
  smoke_check: ''
managed_by: claude-code-setup
blueprint: "$BLUEPRINT"
last_machine: '${MACHINE_NAME}'
last_session: '${CREATED_AT}'
---
<!-- claude-code-setup:managed -->
# Project Profile

## Project Type
- What kind of project is this?

## Why It Exists
- What real-world problem does this project solve?

## Priority Values
- Name the top 2-3 values for decisions here.

## Safe Default Scope
- What areas are usually safe to change without extra approval?
- What areas usually need confirmation first?

## Protected Areas
- Files, flows, or systems that should not be changed casually.

## Common Verification
- Narrowest fast check: ${FAST_CHECK:-<fill in>}
- Broader check: ${FULL_CHECK:-<fill in>}
- Runtime smoke check:

## Operator Notes
- Prefer plain-language explanation when proposing changes? yes
- Prefer options before implementation for open-ended work? yes

## Current Focus
- What kind of work matters most right now?
MARKDOWN
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "init-project: initialized $PROJECT_DIR"
echo "  blueprint:   $BLUEPRINT"
echo "  install:     ${INSTALL:-(none detected)}"
echo "  fast_check:  ${FAST_CHECK:-(none detected)}"
echo "  full_check:  ${FULL_CHECK:-(none detected)}"
echo ""
echo "  created: $MANIFEST"
if [[ "$PROFILE_CREATED" == true ]]; then
  echo "  created: $PROFILE"
else
  echo "  exists:  $PROFILE (kept)"
fi
echo ""
echo "Note: Run OMC deepinit for AGENTS.md generation."
