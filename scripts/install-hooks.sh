#!/usr/bin/env bash
set -euo pipefail

# install-hooks.sh — Register deny-destructive-commands.py hook in ~/.claude/settings.json
# Usage: install-hooks.sh [--dry-run] [--uninstall]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_SRC="$REPO_DIR/hooks/deny-destructive-commands.py"
HOOK_DEST="$HOME/.claude/hooks/deny-destructive-commands.py"
SETTINGS="$HOME/.claude/settings.json"
BACKUP_DIR="$HOME/.claude/backups"

DRY_RUN=false
UNINSTALL=false

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --help|-h)
      cat <<EOF
Usage: $(basename "$0") [--dry-run] [--uninstall]

Register deny-destructive-commands.py as a Bash PreToolUse hook in
~/.claude/settings.json.

Options:
  --dry-run    Show what would happen without making any changes
  --uninstall  Remove the Bash PreToolUse hook entry from settings.json
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "  $*"; }
dlog() { echo "  [dry-run] $*"; }

run() {
  # run <description> <command...>
  local desc="$1"; shift
  if [[ "$DRY_RUN" == true ]]; then
    dlog "$desc"
  else
    log "$desc"
    "$@"
  fi
}

# ── Validate source hook file ─────────────────────────────────────────────────
if [[ ! -f "$HOOK_SRC" ]]; then
  echo "Error: hook source not found: $HOOK_SRC" >&2
  exit 1
fi

echo ""
echo "install-hooks.sh — Claude Code hook installer"
echo "  hook source:  $HOOK_SRC"
echo "  hook dest:    $HOOK_DEST"
echo "  settings:     $SETTINGS"
echo ""

# ── Uninstall path ────────────────────────────────────────────────────────────
if [[ "$UNINSTALL" == true ]]; then
  echo "Mode: uninstall"
  echo ""

  if [[ ! -f "$SETTINGS" ]]; then
    log "settings.json not found — nothing to remove"
    exit 0
  fi

  # Backup before modifying
  TIMESTAMP="$(date +%Y%m%dT%H%M%S)"
  BACKUP="$BACKUP_DIR/settings.json.$TIMESTAMP.bak"
  run "Backup settings.json -> $BACKUP" mkdir -p "$BACKUP_DIR"
  run "Backup settings.json -> $BACKUP" cp "$SETTINGS" "$BACKUP"

  if [[ "$DRY_RUN" == false ]]; then
    python3 - "$SETTINGS" <<'PYEOF'
import json, sys

settings_path = sys.argv[1]
with open(settings_path) as f:
    data = json.load(f)

hooks = data.get("hooks", {})
pre = hooks.get("PreToolUse", [])

# Remove entries with matcher == "Bash" that reference our hook
filtered = [
    entry for entry in pre
    if not (
        entry.get("matcher") == "Bash"
        and any(
            "deny-destructive-commands.py" in h.get("command", "")
            for h in entry.get("hooks", [])
        )
    )
]

if len(filtered) == len(pre):
    print("  no matching hook entry found — nothing to remove")
else:
    # Clean up empty structures
    if filtered:
        data.setdefault("hooks", {})["PreToolUse"] = filtered
    else:
        data.setdefault("hooks", {}).pop("PreToolUse", None)
        if not data.get("hooks"):
            data.pop("hooks", None)

    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("  removed Bash PreToolUse hook entry from settings.json")
PYEOF
  else
    dlog "Remove Bash/deny-destructive-commands.py entry from settings.json"
  fi

  echo ""
  echo "Uninstall complete."
  exit 0
fi

# ── Install path ──────────────────────────────────────────────────────────────
echo "Mode: install"
echo ""

# 1. Backup settings.json
TIMESTAMP="$(date +%Y%m%dT%H%M%S)"
BACKUP="$BACKUP_DIR/settings.json.$TIMESTAMP.bak"

if [[ "$DRY_RUN" == true ]]; then
  dlog "Create backup dir: $BACKUP_DIR"
  if [[ -f "$SETTINGS" ]]; then
    dlog "Backup $SETTINGS -> $BACKUP"
  else
    dlog "settings.json does not exist yet — will create"
  fi
else
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$SETTINGS" ]]; then
    cp "$SETTINGS" "$BACKUP"
    log "Backed up settings.json -> $BACKUP"
  else
    log "settings.json does not exist yet — will create"
  fi
fi

# 2. Copy hook script
run "Create hooks dir: $(dirname "$HOOK_DEST")" mkdir -p "$(dirname "$HOOK_DEST")"
run "Copy hook script -> $HOOK_DEST" cp "$HOOK_SRC" "$HOOK_DEST"

# 3. Append hook entry to settings.json (idempotent)
if [[ "$DRY_RUN" == true ]]; then
  dlog "Append Bash PreToolUse hook to settings.json (if not already present)"
else
  python3 - "$SETTINGS" <<'PYEOF'
import json, sys, os

settings_path = sys.argv[1]

# Load or create settings
if os.path.exists(settings_path):
    with open(settings_path) as f:
        data = json.load(f)
else:
    data = {}

hooks = data.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])

# Check if Bash/deny-destructive-commands.py entry already present
already = any(
    entry.get("matcher") == "Bash"
    and any(
        "deny-destructive-commands.py" in h.get("command", "")
        for h in entry.get("hooks", [])
    )
    for entry in pre
)

if already:
    print("  hook already present in settings.json — skipping (idempotent)")
else:
    pre.append({
        "matcher": "Bash",
        "hooks": [
            {
                "type": "command",
                "command": "python3 ~/.claude/hooks/deny-destructive-commands.py"
            }
        ]
    })
    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("  appended Bash PreToolUse hook to settings.json")
PYEOF
fi

# 4. Verify hook works with a test command
if [[ "$DRY_RUN" == true ]]; then
  dlog "Verify hook: echo 'test' | python3 $HOOK_DEST"
else
  log "Verifying hook script runs correctly..."
  # Send a benign command through the hook; expect exit 0 (allow)
  if echo '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' \
       | python3 "$HOOK_DEST" >/dev/null 2>&1; then
    log "Hook verification passed (benign command allowed)"
  else
    echo "  Warning: hook returned non-zero for benign command (may need input format check)"
  fi
fi

echo ""
echo "Install complete."
echo ""
echo "  hook script: $HOOK_DEST"
echo "  settings:    $SETTINGS"
if [[ "$DRY_RUN" == false && -f "$BACKUP" ]]; then
  echo "  backup:      $BACKUP"
fi
