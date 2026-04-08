# Claude Code Setup 사용 가이드

## 빠른 시작

```bash
git clone https://github.com/nori00000/claude-code-setup.git
cd claude-code-setup
./scripts/install-shell-integration.sh
source ~/.zshrc
./scripts/init-project.sh /절대경로/프로젝트
```

## 매일 쓰는 명령어

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `cl` | 기본 Claude Code 실행 (안전 모드) | `cl 버그 수정해줘` |
| `clp` | 제안 먼저 보기 (3가지 안 제시) | `clp 이 함수 리팩토링` |
| `clr` | 코드 변경 없이 검토만 | `clr 이 PR 위험 요소 체크` |
| `clf` | 피드백 기록 | `clf 5 helpful clear` |
| `cli` | Claude Code 직접 실행 | `cli --help` |

## 프로젝트 설정

프로젝트당 한 번만:
```bash
./scripts/init-project.sh /절대경로/프로젝트
```

`.claude/manifest.json`과 `.claude/project-profile.md` 자동 생성

## 차단되는 위험 명령어

| 명령어 | 이유 |
|--------|------|
| `rm -rf *` | 대량 삭제 방지 |
| `find . -delete` | 재귀 삭제 방지 |
| `git clean -fdx` | 커밋되지 않은 파일 대량 삭제 방지 |
| `git reset --hard` | 작업 내용 손실 방지 |
| `rsync --delete` | 백업 실수 방지 |
| `xargs rm` | 파이프 삭제 방지 |

의도된 삭제는 수동 세션에서 진행

## 다른 컴퓨터에 설치

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc
```
