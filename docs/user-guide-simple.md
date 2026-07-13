# Claude Code Setup 사용 가이드

## 빠른 시작

### 새 Mac — bootstrap (권장)

```bash
brew install gh && gh auth login
git clone git@github.com:nori00000/claude-code-setup.git ~/claude-code-setup
bash ~/claude-code-setup/scripts/bootstrap-mac.sh
source ~/.zshrc
```

이후 재셋업: `dev-setup`

### 기존 Mac — 수동 설치

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
~/claude-code-setup/scripts/install-hooks.sh
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc
```

설치 후: `./scripts/init-project.sh /절대경로/프로젝트`

## 매일 쓰는 명령어

| 명령어 | 설명 |
|--------|------|
| `cl [작업]` | Claude Code 자동 실행 (tmux 보호, 대용량 삭제 확인) |
| `clp [작업]` | 제안만 먼저 보기 (3가지 안 제시, 선택 후 구현) |
| `clr [검토]` | 코드 변경 없이 리스크만 검토 |
| `clf <1-5> <helpful\|neutral\|not_helpful> <clear\|mixed\|unclear>` | 피드백 기록 → ~/.claude/feedback/ |
| `cli [옵션]` | Claude Code 직접 실행 (안전 프롬프트 없음, tmux 적용) |

예: `cl 버그 수정해줘` → tmux 세션 `cl-{폴더명}` 자동 생성 및 실행

## tmux 자동 래핑 (핵심)

모든 `cl*` 명령은 자동으로 tmux 세션을 만들어 실행합니다.

- **SSH 접속 후에도 작업 유지**: 연결이 끊겨도 `tmux attach -t cl-폴더명`으로 재개
- **이미 tmux 내부면**: 자동 감지해서 직접 실행 (재래핑 방지)
- **비활성화**: `CL_NO_TMUX=1 cl [작업]`

## 프로젝트 초기화 (설치 후 1회)

```bash
./scripts/init-project.sh /절대경로/프로젝트
```

자동 생성:
- `.claude/manifest.json` — 프로젝트 메타데이터
- `.claude/project-profile.md` — 구조 및 컨벤션

## 차단되는 위험 명령어 (hook)

| 명령어 | 이유 | 해제 방법 |
|--------|------|---------|
| `rm -rf *` | 대량 삭제 | 수동 터미널에서만 실행 |
| `find . -delete` | 재귀 삭제 | 수동 터미널에서만 실행 |
| `git clean -fdx` | 커밋 미포함 파일 (`-f`/`-fd`/`-fdx` 등 조합 모두 차단) | 수동 터미널에서만 실행 |
| `git reset --hard` | 로컬 작업 손실 | 수동 터미널에서만 실행 |
| `rsync --delete` | 백업 실수 | 수동 터미널에서만 실행 |
| `xargs rm` | xargs와 rm 조합 파이프 삭제 | 수동 터미널에서만 실행 |
| `git push --force` | 원격 브랜치 덮어쓰기 (`--force-with-lease`는 허용) | 수동 터미널에서만 실행 |
| `git checkout -- .` | 미커밋 변경사항 전체 폐기 | 수동 터미널에서만 실행 |

설치: `./scripts/install-hooks.sh` (자동 등록 to ~/.claude/settings.json)

## 다른 컴퓨터에 설치

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
~/claude-code-setup/scripts/install-hooks.sh
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc
```

## 머신 간 개발 이어가기

### Handoff 전 (보내는 쪽)
```bash
git status --short
git branch --show-current          # 예: feature/login-fix
git push origin <current-branch>
```

### 다른 Mac에서 이어받기 (cmux/wrapper 가능)
```bash
cms  # cmux로 접속 (또는 ssh your-main-mac)
cd ~/projects/myproject
git fetch origin
git switch <current-branch>
git pull --ff-only origin <current-branch>
cl "이어서 작업"
```

### 스마트폰에서 이어받기 (plain SSH 전용)

스마트폰에는 wrapper가 없습니다. 원격 Mac에 들어가서 상태 보고 이어받기가 핵심입니다.

```bash
ssh your-main-mac
cd /absolute/path/to/project
git fetch origin
git switch <current-branch>
git pull --ff-only origin <current-branch>
cl "긴급 수정"
```

Fallback (가장 단순):
```bash
ssh your-main-mac
cd /absolute/path/to/project
cl
```

### 자동 핸드오프

다른 머신에서 `cl` 실행하면 이전 머신 정보 자동 표시:

```
$ cl "작업 이어가기"
[handoff] secondary-machine → salpim-web (2026-04-09T14:30Z, branch: feature-xyz)
  ⚠ dirty: 3파일
  ⚠ unpushed: 2커밋
```

- **1순위**: `~/.dev-retrospective/data/machines/` (session-backup 자동 기록 → homelab-orchestration push)
- **2순위**: `.claude/project-profile.md`의 `last_machine` (cl마다 자동 갱신)
- `.claude/`가 gitignore여도 1순위로 핸드오프 작동

## 5단계 운영 플로우

| # | 시나리오 | 명령 |
|---|----------|------|
| 1 | 평소 작업 시작 | `cl "작업"` |
| 2 | 다른 Mac에서 이어받기 | `./scripts/sync-current-branch.sh && cl "작업"` |
| 3 | 스마트폰에서 | `ssh your-main-mac` → `cd <프로젝트>` → `./scripts/check-cmux-health.sh` → `cl` |
| 4 | cmux 불가 시 | `CL_NO_TMUX=1 cl "작업"` |
| 5 | Mac 간 handoff | `./scripts/sync-current-branch.sh` 후 새 Mac에서 `cl` |

## 헬퍼 스크립트

| 스크립트 | 기능 | exit code |
|----------|------|-----------|
| `check-cmux-health.sh` | cmux + claude 건강 체크 | 0=healthy, 10=fallback, 20=unhealthy |
| `sync-current-branch.sh` | 현재 브랜치 fetch+switch+pull --ff-only | 0=OK |
| `ssh-main-mac-project.sh` | 기준 Mac SSH + 프로젝트 이동 | — |
| `open-obsidian-note.sh` | Obsidian 노트 열기 (볼트 외부 파일은 `~/.dev-retrospective/data/sessions/external/`에 래핑) | — |

## 문제 해결

**tmux 우회하고 싶을 때**: `CL_NO_TMUX=1 cl [작업]`

**hook이 작동 안 할 때**: `./scripts/install-hooks.sh` 다시 실행 (idempotent)

**설치 확인**: `ls ~/.claude/hooks/deny-destructive-commands.py` 존재 확인

**shell integration 재설치**: `./scripts/install-shell-integration.sh` (기존 block 자동 치환)
