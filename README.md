# Claude Code Setup

멀티머신 Claude Code 환경의 **단일 진실원천(SST)**. Mac/Windows 양쪽 트랙을 한 레포에서 관리.

> **한눈에 / At a glance**
>
> Portable Claude Code setup scripts and guides for multi-machine development, tmux continuity, and remote handoff workflows.
>
> 한영 프로젝트 설명, 검색 키워드, 저작권 범위: [PROJECT.md](./PROJECT.md) · [NOTICE.md](./NOTICE.md) · [PUBLICATION_REVIEW.md](./PUBLICATION_REVIEW.md)

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
| Codex companion 설치 | `bash scripts/install-codex-companion.sh` |
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

> Mac과 Windows는 서로 다른 방식으로 안전망을 구성한다 (공유 설정 파일이 아니라 각자의 설치 스크립트가 값을 직접 기록) — 아래 표는 각 트랙의 실제 값.

| 레이어 | Mac (`bootstrap-mac.sh`) | Windows (`settings/user-settings.json`) |
|---|---|---|
| Auto mode (classifier) | ✅ `~/.claude/settings.json`에 직접 기록 | ✅ `settings/user-settings.json` |
| Allow 화이트리스트 | ✅ 15개 (도구/카테고리 단위: `Read`,`Write`,`Edit`,`Bash`,`Glob`,`Grep`,`Agent`,`Skill`,`ToolSearch`,`WebFetch`,`WebSearch`,`mcp__filesystem__*`,`mcp__github__*`,`mcp__git__*`,`mcp__fetch__*`) | ✅ 11개 (git 명령 단위 — 아래 "What this repo contains" 참고) |
| Deny 화이트리스트 | ❌ 없음 (Python hook이 역할 대체) | ✅ 6개 |
| Python PreToolUse hook | ✅ `hooks/deny-destructive-commands.py` | (v1.0 미적용 — 다음 라운드) |

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

# 4. Codex도 같이 쓸 경우 (선택)
bash ~/claude-code-setup/scripts/install-codex-companion.sh
```

**bootstrap-mac.sh 순서**:
0. Homebrew + Node.js + python3 설치/확인
1. Claude Code 설치/업데이트
2. OMC (oh-my-claudecode) 설치/업데이트
3. tmux 설치/업데이트
4. **deny-destructive hook 설치** (auto 모드 활성화 전 안전 장치)
5. **shell integration 설치** (`cl`/`clp`/`clr`/`clf`/`cli` + tmux 자동 래핑)
6. `settings.json`에 auto 퍼미션 모드 설정 + 기본 allow 목록 등록 (`Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `Agent`, `Skill`, `ToolSearch`, `WebFetch`, `WebSearch`, `mcp__filesystem__*`, `mcp__github__*`, `mcp__git__*`, `mcp__fetch__*`)
7. `dev-setup` alias 등록
8. tmux `claude` 세션 준비 (기존 세션 재사용 또는 신규 생성)

이후 재셋업은 한 단어: `dev-setup`

### 기존 프로젝트 초기화

```bash
~/claude-code-setup/scripts/init-project.sh /absolute/path/to/your-project
```

## What this repo contains

- `scripts/bootstrap-mac.sh`: 새 Mac 전체 셋업 (Homebrew → Claude Code → OMC → tmux → hook → shell 함수 → auto 모드)
- `scripts/setup-tmux-yazi.sh`: WSL Ubuntu에서 tmux + yazi 작업환경 설치
- `hooks/deny-destructive-commands.py`: safety hook blocking `rm -rf`, `git reset --hard`, `git clean` (any flag combo with `d`/`f`/`x`/`X`, e.g. `-f`, `-fd`, `-fdx`), `find -delete`, `rsync --delete`, `xargs rm`, `git push --force`, `git checkout -- .`
- `templates/project-profile.md`: per-project profile template with YAML frontmatter
- `templates/manifest.schema.json`: JSON Schema for `.claude/manifest.json` (validates `managed_by`, `blueprint`, `managed_files`, timestamps; `additionalProperties: false`)
- `scripts/init-project.sh`: project initializer with blueprint detection (web-app/python-service/generic)
- `scripts/install-shell-integration.sh`: shell functions `cl`/`clp`/`clr`/`clf`/`cli` with tmux wrapping and machine handoff
- `scripts/install-hooks.sh`: hook installer (`--dry-run`, `--uninstall`, `--help`)
- `scripts/install-codex-companion.sh`: Codex auto-resume/session logger 설치를 `dev-retrospective` 정본에 위임
- `scripts/check-cmux-health.sh`: cmux + claude 건강 체크 (0/10/20 exit code)
- `scripts/sync-current-branch.sh`: branch-aware handoff helper
- `scripts/ssh-main-mac-project.sh`: 기준 Mac SSH + 프로젝트 이동
- `scripts/open-obsidian-note.sh`: Obsidian 노트 열기 — 볼트 외부 파일은 `~/.dev-retrospective/data/sessions/external/`에 세션 노트로 래핑한 뒤 Obsidian에서 열림 (vault sessions 경로는 `VAULT_SESSIONS_SUBDIR` 환경변수로 오버라이드 가능, 기본값 `00. Inbox/03. AI Agent/sessions`; dev-retrospective 루트는 `DEV_RETRO_ROOT`, 볼트 이름/위치는 `DEFAULT_OBSIDIAN_VAULT_NAME`/`DEFAULT_OBSIDIAN_VAULT_ROOT`로 오버라이드 가능; `~/.dev-retrospective/scripts/vault-detect.sh`가 있으면 `find_vault()`로 볼트 자동 감지)
- `docs/user-guide-detailed.md`: 상세 사용 가이드 (한국어)
- `docs/user-guide-simple.md`: 빠른 시작 가이드 (한국어)
- `docs/tmux-yazi-beginner-handout.html`: 초보자/중학생 대상 tmux + yazi 교육자료
- `devlog/`: 개발 로그 — `daily/` (일별 리뷰) + `sessions/` (세션별 기록)

## Multi-Machine Setup

새 머신에서 한 줄로 설치 (SSH 키 미설정 환경은 HTTPS; SSH 키 설정 완료 시 `git@github.com:nori00000/claude-code-setup.git` 사용 가능):

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
~/claude-code-setup/scripts/install-hooks.sh
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc

# Codex도 함께 쓸 경우
~/claude-code-setup/scripts/install-codex-companion.sh
```

### Codex Companion

이 레포는 Codex auto-resume 로직 자체를 복제하지 않습니다. 대신 `scripts/install-codex-companion.sh`가
`dev-retrospective/scripts/setup-codex-logger.sh`를 호출해 아래를 설치합니다.

- bare `codex` → 최근 세션 `resume --last`
- `codex --new` → 새 세션 강제 시작
- `~/.codex/hooks/codex-session-logger.sh`
- launchd `codex-session-watcher`, `daily-canvas`

즉 정본은 `dev-retrospective`, 이 레포는 진입점만 제공합니다.

### 머신 간 연속 개발

**Handoff 전 (보내는 쪽):**
```bash
git status --short
git branch --show-current          # 예: feature/login-fix
git push origin <current-branch>
```

**다른 Mac에서 이어받기 (cmux/wrapper 가능):**
```bash
cms  # 또는 ssh your-main-mac
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
1. `~/.dev-retrospective/data/machines/` — 세션 종료 시 자동 기록, homelab-orchestration으로 push
2. `.claude/project-profile.md` — cl 실행 시 last_machine 갱신 (git push 시 공유)

**tmux 자동 래핑:** SSH로 접속해서 `cl` 실행하면 `cl-<프로젝트>-<경로 해시>` tmux 세션을 자동 생성합니다. 같은 폴더명인 다른 프로젝트도 각각 별도 세션을 사용하며, 심볼릭 링크와 실제 경로는 같은 프로젝트로 인식합니다. SSH가 끊겨도 프로젝트 디렉터리에서 `cl`을 다시 실행하면 재접속하며, `CL_NO_TMUX=1 cl`로 비활성화할 수 있습니다.

## 5단계 운영 플로우

| # | 시나리오 | 명령 |
|---|----------|------|
| 1 | 평소 작업 시작 | `cl "작업"` |
| 2 | 다른 Mac에서 이어받기 | `./scripts/sync-current-branch.sh && cl "작업"` |
| 3 | 스마트폰에서 | `ssh your-main-mac` → `cd <프로젝트>` → `./scripts/check-cmux-health.sh` → `cl` |
| 4 | cmux 불가 시 | `CL_NO_TMUX=1 cl "작업"` |
| 5 | Mac 간 handoff | `./scripts/sync-current-branch.sh` 후 새 Mac에서 `cl` |

## Helper Scripts

| 스크립트 | 기능 | exit code |
|----------|------|-----------|
| `check-cmux-health.sh` | cmux + claude 건강 체크 | 0=healthy, 10=fallback, 20=unhealthy |
| `sync-current-branch.sh` | 현재 브랜치 fetch+switch+pull --ff-only | 0=OK |
| `ssh-main-mac-project.sh` | 기준 Mac SSH + 프로젝트 자동 이동 | — |
| `open-obsidian-note.sh` | Obsidian 노트 열기 (볼트 외부 파일은 `~/.dev-retrospective/data/sessions/external/`에 래핑) | — |

## Shell Functions

| Function | Purpose |
|----------|---------|
| `cl`  | Launch Claude Code with default safety prompt |
| `clp` | Proposal-first mode (3 options before implementing) |
| `clr` | Review-only mode (no code changes) |
| `clf` | Quick feedback capture: `clf <1-5> <helpful\|neutral\|not_helpful> <clear\|mixed\|unclear> [comment]` |
| `cli` | Direct claude launch (no safety prompt, no handoff display; tmux-wrapped) |

## Project Setup

Run once per project:

```bash
./scripts/init-project.sh /absolute/path/to/your-project
```

This detects project type and creates:
- `.claude/manifest.json` — managed file registry
- `.claude/project-profile.md` — project profile with verification commands

For `AGENTS.md` generation, run OMC deepinit after init:

```bash
claude /oh-my-claudecode:deepinit
```

Blueprint detection:
- `package.json` present → **web-app**
- `pyproject.toml`/`setup.py`/`requirements.txt` → **python-service**
- Otherwise → **generic**

## Destructive Command Safety

The hook `deny-destructive-commands.py` is registered as a Claude Code `PreToolUse` hook on the `Bash` tool. It blocks:

- `rm` with flags containing `r` or `f` (e.g. `-rf`, `-fr`, `-r`, `-f`, `-Rf`) targeting wildcards, `./`, `..`, `.`, home, root, or expanded paths
- `find ... -delete`
- `git clean` with `-f`, `-fd`, `-fx`, `-fdx`, or any flag combination containing `d`, `f`, `x`, or `X`
- `git reset --hard`
- `rsync --delete`
- `xargs rm`
- `git push --force` (without `--force-with-lease`)
- `git checkout -- .` (discards all uncommitted changes)

## Notes

- Shell integration detects existing `cc()` functions and never overwrites them
- Project init refuses to overwrite existing `.claude/manifest.json` without `--force`
- All scripts use `set -euo pipefail` for safety
- `scripts/open-obsidian-note.sh` opens Markdown notes in the default `your-obsidian-vault` vault and, for out-of-vault files, creates an external-doc note under `~/.dev-retrospective/data/sessions/external/` so the dev-retrospective Obsidian workflow remains the source of truth
- `.gitignore` excludes `.omc/`, `__pycache__/`, `*.pyc`, `.DS_Store` — OMC state files are local-only and not tracked
