# Claude Code Setup

Portable Claude Code setup for multiple machines, with low-friction defaults.

Ported from [codex-setup](https://github.com/nori00000/codex-setup) concepts, adapted for Claude Code architecture.

## Quick Start

```bash
git clone https://github.com/nori00000/claude-code-setup.git
cd claude-code-setup
./scripts/install-shell-integration.sh
source ~/.zshrc
./scripts/init-project.sh /absolute/path/to/your-project
```

## What this repo contains

- `hooks/deny-destructive-commands.py`: safety hook blocking `rm -rf`, `git reset --hard`, `git clean -fdx`, `find -delete`, `rsync --delete`, `xargs rm`
- `templates/project-profile.md`: per-project profile template with YAML frontmatter for verification commands
- `templates/manifest.schema.json`: JSON Schema for managed harness manifests
- `scripts/init-project.sh`: project initializer with blueprint detection (web-app/python-service/generic)
- `scripts/install-shell-integration.sh`: shell aliases `cl`/`clp`/`clr`/`clf`/`cli`

## Shell Aliases

| Alias | Purpose |
|-------|---------|
| `cl`  | Launch Claude Code with default safety prompt |
| `clp` | Proposal-first mode (3 options before implementing) |
| `clr` | Review-only mode (no code changes) |
| `clf` | Quick feedback capture |
| `cli` | Direct claude launch |

## Project Setup

Run once per project:

```bash
./scripts/init-project.sh /absolute/path/to/your-project
```

This detects project type and creates:
- `.claude/manifest.json` — managed file registry
- `.claude/project-profile.md` — project profile with verification commands

Blueprint detection:
- `package.json` present → **web-app**
- `pyproject.toml`/`setup.py`/`requirements.txt` → **python-service**
- Otherwise → **generic**

## Destructive Command Safety

The hook `deny-destructive-commands.py` is registered as a Claude Code `PreToolUse` hook on the `Bash` tool. It blocks:

- `rm -rf` with wildcards, home, root, or expanded paths
- `find ... -delete`
- `git clean -fdx`
- `git reset --hard`
- `rsync --delete`
- `xargs rm`

## Notes

- Shell integration detects existing `cc()` functions and never overwrites them
- Project init refuses to overwrite existing `.claude/manifest.json` without `--force`
- All scripts use `set -euo pipefail` for safety
