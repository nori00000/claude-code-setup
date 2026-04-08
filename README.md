# Claude Code Setup

Portable Claude Code setup for multiple machines, with low-friction defaults.

Ported from [codex-setup](https://github.com/nori00000/codex-setup) concepts, adapted for Claude Code architecture.

## Quick Start

```bash
git clone https://github.com/nori00000/claude-code-setup.git
cd claude-code-setup
./scripts/install-hooks.sh
./scripts/install-shell-integration.sh
source ~/.zshrc
./scripts/init-project.sh /absolute/path/to/your-project
```

## What this repo contains

- `hooks/deny-destructive-commands.py`: safety hook blocking `rm -rf`, `git reset --hard`, `git clean -fdx`, `find -delete`, `rsync --delete`, `xargs rm`
- `templates/project-profile.md`: per-project profile template with YAML frontmatter for verification commands
- `templates/manifest.schema.json`: JSON Schema for managed harness manifests
- `scripts/init-project.sh`: project initializer with blueprint detection (web-app/python-service/generic)
- `scripts/install-shell-integration.sh`: shell aliases `cl`/`clp`/`clr`/`clf`/`cli` with tmux wrapping and machine handoff
- `scripts/install-hooks.sh`: one-command hook installer (`--dry-run`, `--uninstall`)
- `docs/user-guide-detailed.md`: 상세 사용 가이드 (한국어)
- `docs/user-guide-simple.md`: 빠른 시작 가이드 (한국어)

## Multi-Machine Setup

새 머신에서 한 줄로 설치:

```bash
git clone https://github.com/nori00000/claude-code-setup.git
cd claude-code-setup
./scripts/install-hooks.sh && ./scripts/install-shell-integration.sh && source ~/.zshrc
```

### 머신 간 연속 개발

**Handoff 전 (보내는 쪽):**
```bash
git status --short
git branch --show-current          # 예: feature/login-fix
git push origin <current-branch>
```

**다른 Mac에서 이어받기 (cmux/wrapper 가능):**
```bash
cms  # 또는 ssh studio
cd ~/projects/myproject
git fetch origin
git switch <current-branch>
git pull --ff-only origin <current-branch>
cl "이어서 작업"
```

**스마트폰에서 (plain SSH 전용):**
```bash
ssh your-main-mac
cd /absolute/path/to/project
git fetch origin
git switch <current-branch>
git pull --ff-only origin <current-branch>
cl
```

**동기화 경로 (2중):**
1. `dev-retrospective/data/machines/` — 세션 종료 시 자동 기록, homelab-orchestration으로 push
2. `.claude/project-profile.md` — cl 실행 시 last_machine 갱신 (git push 시 공유)

**tmux 자동 래핑:** SSH로 접속해서 `cl` 실행하면 `cl-<프로젝트>` tmux 세션 자동 생성. SSH 끊겨도 세션 유지. `CL_NO_TMUX=1 cl`로 비활성화.

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
- `scripts/open-obsidian-note.sh` opens Markdown notes in the default `Obsidian-0.1` vault and, for out-of-vault files, creates an external-doc note under `~/.dev-retrospective/data/sessions/external/` so the dev-retrospective Obsidian workflow remains the source of truth
