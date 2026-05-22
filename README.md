# Claude Code Setup

멀티머신 Claude Code 환경의 **단일 진실원천(SST)**. Mac/Windows 양쪽 트랙을 한 레포에서 관리.

Ported from [codex-setup](https://github.com/nori00000/codex-setup) concepts, adapted for Claude Code architecture.

---

## 빠른 진입

| 목적 | 파일 |
|---|---|
| 현재 머신 인벤토리 (Mac/Windows/기타) | [`FLEET.md`](FLEET.md) |
| **Windows 셋업 가이드 (v1.0)** | [`playbooks/windows-setup.md`](playbooks/windows-setup.md) |
| WSL tmux + yazi 작업환경 | [`playbooks/tmux-yazi-wsl.md`](playbooks/tmux-yazi-wsl.md), [`docs/tmux-yazi-beginner-handout.html`](docs/tmux-yazi-beginner-handout.html) |
| **Claude Code + Codex tmux 워크플로우 (2026-05)** | [`playbooks/tmux-claude-code-workflow.md`](playbooks/tmux-claude-code-workflow.md) — 초보 친화 매뉴얼, 단축키 표, 원격/모바일 접속 포함 |
| macOS 셋업 (현행) | [`docs/user-guide-detailed.md`](docs/user-guide-detailed.md), [`docs/user-guide-simple.md`](docs/user-guide-simple.md) |
| macOS 플레이북 v1.0 (작성 예정) | [`playbooks/macos-setup.md`](playbooks/macos-setup.md) |
| 새 Windows 머신 원라이너 | `pwsh -File scripts/bootstrap-windows.ps1` |
| 새 Mac 원라이너 | `bash scripts/bootstrap-mac.sh` |
| 진단만 (Windows) | `pwsh -File scripts/diagnose-windows.ps1` |
| 다른 AI에게 셋업 위임 (Windows) | [`prompts/master-setup-prompt.md`](prompts/master-setup-prompt.md) |
| 공통 settings.json (모든 머신) | [`settings/user-settings.json`](settings/user-settings.json) |
| 변경 이력 | [`CHANGELOG.md`](CHANGELOG.md) |

### 새 Windows 머신 30초 부트스트랩

```powershell
# 사전: winget install --id GitHub.cli && gh auth login
gh repo clone nori00000/claude-code-setup $env:USERPROFILE\projects\claude-code-setup
pwsh -File $env:USERPROFILE\projects\claude-code-setup\scripts\bootstrap-windows.ps1
```

`-DryRun` 플래그로 변경 없이 미리 확인 가능. 자세한 흐름은 [`playbooks/windows-setup.md`](playbooks/windows-setup.md) 참고.

### 안전망 구조

| 레이어 | Mac | Windows |
|---|---|---|
| Auto mode (classifier) | ✅ `settings/user-settings.json` | ✅ 동일 |
| Deny 화이트리스트 6개 | ✅ 동일 | ✅ 동일 |
| Python PreToolUse hook | ✅ `hooks/deny-destructive-commands.py` | (v1.0 미적용 — 다음 라운드) |
| Allow 화이트리스트 9개 | ✅ 동일 | ✅ 동일 |

---

## Quick Start (새 Mac bootstrap)

한 번에 전체 환경 구성:

```bash
# 1. GitHub CLI 설치 + 인증 (Private 레포 clone용)
brew install gh && gh auth login

# 2. 레포 clone
git clone git@github.com:nori00000/claude-code-setup.git ~/claude-code-setup

# 3. bootstrap 실행
bash ~/claude-code-setup/scripts/bootstrap-mac.sh
source ~/.zshrc
```

**bootstrap-mac.sh 순서**:
1. Homebrew + Node.js 설치/확인
2. Claude Code 설치/업데이트
3. OMC (oh-my-claudecode) 설치/업데이트
4. tmux 설치/업데이트
5. **deny-destructive hook 설치** (auto 모드 활성화 전 안전 장치)
6. **shell integration 설치** (`cl`/`clp`/`clr`/`clf`/`cli` + tmux 자동 래핑)
7. `settings.json`에 auto 퍼미션 모드 설정
8. `dev-setup` alias 등록
9. tmux `claude` 세션 생성

이후 재셋업은 한 단어: `dev-setup`

### 기존 프로젝트 초기화

```bash
~/claude-code-setup/scripts/init-project.sh /absolute/path/to/your-project
```

## What this repo contains

- `scripts/bootstrap-mac.sh`: 새 Mac 전체 셋업 (Homebrew → Claude Code → OMC → tmux → hook → aliases → auto 모드)
- `scripts/setup-tmux-yazi.sh`: WSL Ubuntu에서 tmux + yazi 작업환경 설치
- `hooks/deny-destructive-commands.py`: safety hook blocking `rm -rf`, `git reset --hard`, `git clean -fdx`, `find -delete`, `rsync --delete`, `xargs rm`, `git push --force`, `git checkout -- .`
- `templates/project-profile.md`: per-project profile template with YAML frontmatter
- `templates/manifest.schema.json`: JSON Schema for managed harness manifests
- `scripts/init-project.sh`: project initializer with blueprint detection (web-app/python-service/generic)
- `scripts/install-shell-integration.sh`: shell aliases `cl`/`clp`/`clr`/`clf`/`cli` with tmux wrapping and machine handoff
- `scripts/install-hooks.sh`: hook installer (`--dry-run`, `--uninstall`)
- `scripts/check-cmux-health.sh`: cmux + claude 건강 체크 (0/10/20 exit code)
- `scripts/sync-current-branch.sh`: branch-aware handoff helper
- `scripts/ssh-main-mac-project.sh`: 기준 Mac SSH + 프로젝트 이동
- `docs/user-guide-detailed.md`: 상세 사용 가이드 (한국어)
- `docs/user-guide-simple.md`: 빠른 시작 가이드 (한국어)
- `docs/tmux-yazi-beginner-handout.html`: 초보자/중학생 대상 tmux + yazi 교육자료

## Multi-Machine Setup

새 머신에서 한 줄로 설치:

```bash
git clone https://github.com/nori00000/claude-code-setup.git
cd claude-code-setup
./scripts/install-shell-integration.sh && ./scripts/install-hooks.sh && source ~/.zshrc
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

## 5단계 운영 플로우

| # | 시나리오 | 명령 |
|---|----------|------|
| 1 | 평소 작업 시작 | `cl "작업"` |
| 2 | 다른 Mac에서 이어받기 | `./scripts/sync-current-branch.sh && cl "작업"` |
| 3 | 스마트폰에서 | `ssh studio` → `cd <프로젝트>` → `./scripts/check-cmux-health.sh` → `cl` |
| 4 | cmux 불가 시 | `CL_NO_TMUX=1 cl "작업"` |
| 5 | Mac 간 handoff | `./scripts/sync-current-branch.sh` 후 새 Mac에서 `cl` |

## Helper Scripts

| 스크립트 | 기능 | exit code |
|----------|------|-----------|
| `check-cmux-health.sh` | cmux + claude 건강 체크 | 0=healthy, 10=fallback, 20=unhealthy |
| `sync-current-branch.sh` | 현재 브랜치 fetch+switch+pull --ff-only | 0=OK |
| `ssh-main-mac-project.sh` | 기준 Mac SSH + 프로젝트 자동 이동 | — |

## Shell Aliases

| Alias | Purpose |
|-------|---------|
| `cl`  | Launch Claude Code with default safety prompt |
| `clp` | Proposal-first mode (3 options before implementing) |
| `clr` | Review-only mode (no code changes) |
| `clf` | Quick feedback capture |
| `cli` | Direct claude launch (no safety prompt, no handoff display; tmux-wrapped) |

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
- `git push --force` (without `--force-with-lease`)
- `git checkout -- .` (discards all uncommitted changes)

## Notes

- Shell integration detects existing `cc()` functions and never overwrites them
- Project init refuses to overwrite existing `.claude/manifest.json` without `--force`
- All scripts use `set -euo pipefail` for safety
- `scripts/open-obsidian-note.sh` opens Markdown notes in the default `Obsidian-0.1` vault and, for out-of-vault files, creates an external-doc note under `~/.dev-retrospective/data/sessions/external/` so the dev-retrospective Obsidian workflow remains the source of truth
