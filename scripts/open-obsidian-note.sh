#!/usr/bin/env bash
set -euo pipefail

DEFAULT_OBSIDIAN_VAULT_NAME="${DEFAULT_OBSIDIAN_VAULT_NAME:-your-obsidian-vault}"
DEFAULT_OBSIDIAN_VAULT_ROOT="${DEFAULT_OBSIDIAN_VAULT_ROOT:-${HOME}/Documents/${DEFAULT_OBSIDIAN_VAULT_NAME}}"
DEV_RETRO_ROOT="${DEV_RETRO_ROOT:-${HOME}/.dev-retrospective}"
DEV_RETRO_VAULT_DETECT="${DEV_RETRO_ROOT}/scripts/vault-detect.sh"
DEV_RETRO_SESSIONS_DIR="${DEV_RETRO_ROOT}/data/sessions"
VAULT_SESSIONS_SUBDIR_DEFAULT="00. Inbox/03. AI Agent/sessions"

if [[ $# -ne 1 ]]; then
  echo "usage: ./scripts/open-obsidian-note.sh /absolute/path/to/note.md" >&2
  exit 2
fi

NOTE_PATH="$1"

if [[ "${NOTE_PATH}" != /* ]]; then
  echo "note path must be absolute: ${NOTE_PATH}" >&2
  exit 2
fi

if [[ ! -f "${NOTE_PATH}" ]]; then
  echo "note does not exist: ${NOTE_PATH}" >&2
  exit 1
fi

detect_vault_root() {
  if [[ -f "${DEV_RETRO_VAULT_DETECT}" ]]; then
    # shellcheck disable=SC1090
    source "${DEV_RETRO_VAULT_DETECT}"
    if command -v find_vault >/dev/null 2>&1; then
      local detected
      detected="$(find_vault 2>/dev/null || true)"
      if [[ -n "${detected}" ]] && [[ -d "${detected}" ]]; then
        printf '%s\n' "${detected}"
        return 0
      fi
    fi
  fi
  if [[ -d "${DEFAULT_OBSIDIAN_VAULT_ROOT}" ]]; then
    printf '%s\n' "${DEFAULT_OBSIDIAN_VAULT_ROOT}"
    return 0
  fi
  return 1
}

slugify_basename() {
  python3 - "$1" <<'PY'
import pathlib
import re
import sys

name = pathlib.Path(sys.argv[1]).stem.lower()
slug = re.sub(r"[^a-z0-9]+", "-", name).strip("-")
print(slug or "note")
PY
}

VAULT_ROOT="$(detect_vault_root || true)"
if [[ -z "${VAULT_ROOT}" ]]; then
  echo "Obsidian vault not found. Configure DEFAULT_OBSIDIAN_VAULT_ROOT or create ${DEFAULT_OBSIDIAN_VAULT_ROOT}." >&2
  exit 1
fi

VAULT_SESSIONS_SUBDIR="${VAULT_SESSIONS_SUBDIR:-${VAULT_SESSIONS_SUBDIR_DEFAULT}}"
VAULT_SESSIONS_DIR="${VAULT_ROOT}/${VAULT_SESSIONS_SUBDIR}"

OPEN_PATH="$NOTE_PATH"
if [[ "${NOTE_PATH}" != "${VAULT_ROOT}"* ]]; then
  mkdir -p "${DEV_RETRO_SESSIONS_DIR}/external"
  SLUG="$(slugify_basename "${NOTE_PATH}")"
  DATE_PREFIX="$(date +%Y-%m-%d-%H%M)"
  SESSION_NOTE_PATH="${DEV_RETRO_SESSIONS_DIR}/external/${DATE_PREFIX}-open-${SLUG}.md"

  python3 - "${NOTE_PATH}" "${SESSION_NOTE_PATH}" <<'PY'
import pathlib
import sys

source_path = pathlib.Path(sys.argv[1]).resolve()
session_note_path = pathlib.Path(sys.argv[2])

body = source_path.read_text()
content = f"""---
type: session-log
aliases:
  - "Open {source_path.name}"
date created: {session_note_path.stem[:10]}
date modified: {session_note_path.stem[:10]}
tags:
  - session-log
  - external-doc
source_path: "{source_path}"
---

# External Document View

> Source: `{source_path}`
> This note was generated to open an out-of-vault development document inside the dev-retrospective Obsidian sessions system.

---

{body}
"""
session_note_path.write_text(content)
PY
  OPEN_PATH="${SESSION_NOTE_PATH}"
fi

URI="$(python3 - "${OPEN_PATH}" "${DEFAULT_OBSIDIAN_VAULT_NAME}" "${VAULT_ROOT}" "${VAULT_SESSIONS_DIR}" "${DEV_RETRO_SESSIONS_DIR}" "${VAULT_SESSIONS_SUBDIR}" <<'PY'
import pathlib
import sys
import urllib.parse

note_path = pathlib.Path(sys.argv[1]).resolve()
vault_name = sys.argv[2]
vault_root = pathlib.Path(sys.argv[3]).resolve()
vault_sessions_dir = pathlib.Path(sys.argv[4]).resolve()
dev_retro_sessions_dir = pathlib.Path(sys.argv[5]).resolve()
vault_sessions_subdir = sys.argv[6]

try:
    relative_note = note_path.relative_to(vault_root)
    file_arg = relative_note.as_posix()
except ValueError:
    relative_note = note_path.relative_to(dev_retro_sessions_dir)
    file_arg = str(pathlib.Path(vault_sessions_subdir) / relative_note).replace("\\", "/")
print(
    "obsidian://open?vault="
    + urllib.parse.quote(vault_name)
    + "&file="
    + urllib.parse.quote(file_arg)
)
PY
)"

open "${URI}"
