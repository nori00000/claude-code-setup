# Claude Code Setup 사용 가이드

## 빠른 시작

```bash
git clone https://github.com/nori00000/claude-code-setup.git
cd claude-code-setup
./scripts/install-hooks.sh
./scripts/install-shell-integration.sh
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
| `cli [옵션]` | Claude Code 직접 실행 (tmux 우회) |

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
| `git clean -fdx` | 커밋 미포함 파일 | 수동 터미널에서만 실행 |
| `git reset --hard` | 로컬 작업 손실 | 수동 터미널에서만 실행 |
| `rsync --delete` | 백업 실수 | 수동 터미널에서만 실행 |

설치: `./scripts/install-hooks.sh` (자동 등록 to ~/.claude/settings.json)

## 다른 컴퓨터에 설치

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
~/claude-code-setup/scripts/install-hooks.sh
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc
```

## 이동 중 개발 (SSH)

1. 현재 작업: `cl [작업]` → tmux 세션 생성
2. SSH 접속 후: `tmux attach -t cl-{폴더명}`
3. 작업 이어가기: 세션 복원, 프롬프트 계속 실행

별칭 추가: `alias cmux='tmux attach -t'`

## 문제 해결

**tmux 우회하고 싶을 때**: `CL_NO_TMUX=1 cl [작업]`

**hook이 작동 안 할 때**: `./scripts/install-hooks.sh` 다시 실행 (idempotent)

**설치 확인**: `ls ~/.claude/hooks/deny-destructive-commands.py` 존재 확인

**shell integration 재설치**: `./scripts/install-shell-integration.sh` (기존 block 자동 치환)
