# Claude Code Setup 상세 사용 가이드 (v1.0)

## 1. 개요

**Claude Code Setup**은 Codex Setup에서 포팅된 프로젝트로, Claude Code 멀티머신 개발 환경에서 저마찰(low-friction) 워크플로우를 제공하는 도구 모음입니다.

### 이 프로젝트가 필요한 이유

- **파괴적 명령어 자동 차단**: `rm -rf`, `git reset --hard` 등 위험한 명령 자동 차단
- **프로젝트 프로필**: 각 프로젝트의 검증 명령, 우선값, 보호 영역을 YAML로 선언
- **멀티머신 동기화**: 여러 MacBook/스튜디오 간 일관된 설정 유지
- **tmux 자동 래핑**: 터미널 밖에서 Claude Code 실행 시 자동으로 세션 생성 (SSH 끊겨도 유지)
- **OMC 연동**: oh-my-claudecode 검증 모듈과의 통합

### 포함 내용

| 파일 | 용도 |
|------|------|
| `hooks/deny-destructive-commands.py` | Claude Code PreToolUse 훅 — 위험한 명령어 차단 |
| `scripts/install-hooks.sh` | 훅 설치/제거 스크립트 (--dry-run, --uninstall 옵션) |
| `scripts/install-shell-integration.sh` | zsh 별칭 설치 (cl/clp/clr/clf/cli) + tmux 래핑 |
| `scripts/init-project.sh` | 프로젝트 초기화 — manifest.json, project-profile.md 생성 |
| `templates/project-profile.md` | 프로젝트 프로필 템플릿 |
| `templates/manifest.schema.json` | manifest.json의 JSON Schema |
| `scripts/open-obsidian-note.sh` | Obsidian 노트 열기 — 볼트 외부 파일은 dev-retrospective 세션 노트로 래핑 |

---

## 2. 설치 방법

### 2.1 저장소 클론

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
cd ~/claude-code-setup
```

### 2.2 4단계 설치 프로세스

#### 단계 1: Shell 별칭 설치 (tmux 래핑 포함)

```bash
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc
```

이 스크립트는:
- zsh 별칭 5개 추가 (cl, clp, clr, clf, cli)
- **tmux 자동 래핑** 기능 활성화
- 기존 `cc()` 함수 자동 감지

**확인**:
```bash
cl --help  # 작동하면 설치 완료
```

#### 단계 2: 훅 설치 및 설정 (선택사항)

훅을 통해 파괴적 명령어를 자동으로 차단합니다.

```bash
~/claude-code-setup/scripts/install-hooks.sh
```

**옵션들**:
```bash
# 실제 변경 없이 미리 확인
./scripts/install-hooks.sh --dry-run

# 훅 제거 (설치 취소)
./scripts/install-hooks.sh --uninstall

# 훅 도움말
./scripts/install-hooks.sh --help
```

**훅이 하는 작업**:
1. `~/.claude/hooks/` 디렉토리 생성
2. `deny-destructive-commands.py` 복사
3. `~/.claude/settings.json`에 PreToolUse 훅 등록 (idempotent)
4. settings.json 자동 백업 생성 (`~/.claude/backups/settings.json.{timestamp}.bak`)

**확인**:
```bash
cat ~/.claude/settings.json | grep -A 5 "PreToolUse"
```

정상이면:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/deny-destructive-commands.py"
          }
        ]
      }
    ]
  }
}
```

**settings.json 백업/롤백**:
```bash
# 백업 위치 확인
ls -la ~/.claude/backups/

# 특정 시점으로 롤백
cp ~/.claude/backups/settings.json.20260409T103000Z.bak ~/.claude/settings.json
```

#### 단계 3: 프로젝트 초기화

각 프로젝트에서 **한 번만** 실행합니다.

```bash
~/claude-code-setup/scripts/init-project.sh /절대경로/your-project
```

자세한 설명은 섹션 3 참고.

#### 단계 4: 새 터미널 열기

모든 설치 완료 후:
```bash
source ~/.zshrc
# 또는 새 터미널 탭을 열기
```

---

## 3. 프로젝트 초기화

### 3.1 블루프린트 자동 감지

스크립트가 프로젝트 유형을 자동으로 감지합니다:

| 감지 기준 | 블루프린트 | 검증 명령 |
|----------|-----------|---------|
| `package.json` 있음 | **web-app** | npm install → npm run lint/type-check/typecheck/check/test → npm run build && npm test |
| `pyproject.toml` / `setup.py` / `requirements.txt` | **python-service** | pip install -e . → python -m pytest -x --tb=short → python -m pytest |
| 둘 다 없음 | **generic** | (검증 명령 미지정) |

**fast_check 우선순위** (web-app):
1. `lint` 스크립트가 있으면 사용
2. 없으면 `type-check` 확인
3. 없으면 `typecheck` 확인
4. 없으면 `check` 확인
5. 모두 없으면 `npm test` 사용

### 3.2 생성되는 파일

```
.claude/
├── manifest.json          ← 관리 파일 레지스트리
└── project-profile.md     ← 프로젝트 프로필 (YAML frontmatter + 마크다운)
```

**manifest.json 예시** (web-app):
```json
{
  "managed_by": "claude-code-setup",
  "blueprint": "web-app",
  "created_at": "2026-04-09T10:30:00Z",
  "updated_at": "2026-04-09T10:30:00Z",
  "managed_files": [
    { "path": ".claude/manifest.json", "mode": "create" },
    { "path": ".claude/project-profile.md", "mode": "skip_if_exists" }
  ]
}
```

### 3.3 project-profile.md 구조

생성된 프로필은 YAML frontmatter + 마크다운으로 구성합니다.

**Frontmatter 영역** (OMC verification module이 읽음):
```yaml
---
verification:
  install: "npm install"
  fast_check: "npm run lint"
  full_check: "npm run build && npm test"
  smoke_check: ""
managed_by: claude-code-setup
blueprint: "web-app"
last_machine: "studio"
last_session: "2026-04-09T10:30:00Z"
---
```

**주요 필드**:
| 필드 | 설명 | 예시 |
|------|------|------|
| `verification.install` | 의존성 설치 명령 | `npm install`, `pip install -e .` |
| `verification.fast_check` | 가장 빠른 검증 (lint, 빠른 테스트 서브셋) | `npm run lint`, `python -m pytest -x` |
| `verification.full_check` | 전체 검증 (build + 모든 테스트) | `npm run build && npm test` |
| `verification.smoke_check` | 런타임 검증 (서버 시작 테스트 등) | `npm run dev & sleep 5 && curl ...` |
| `blueprint` | 프로젝트 유형 | `web-app`, `python-service`, `generic` |
| `last_machine` | 마지막으로 작업한 머신 | `studio`, `air`, `pro` |
| `last_session` | 마지막 세션 시간 | ISO 8601 형식 |

**마크다운 영역** (사람이 읽음):
```markdown
# Project Profile

## Project Type
- React + Express 풀스택 애플리케이션

## Why It Exists
- 사용자 커뮤니티 관리 플랫폼

## Priority Values
1. 데이터 무결성
2. API 응답 속도 < 500ms
3. 모바일 친화성

## Safe Default Scope
- 프론트엔드 UI/스타일: 자유 변경
- 테스트 추가: 자유 변경
- 문서/주석: 자유 변경
- API 스키마: 먼저 확인 필요
- 데이터베이스 마이그레이션: 먼저 확인 필요

## Protected Areas
- `src/db/migrations/`: 버전 관리 중요
- `api/auth/`: 보안 검토 필수
- `.github/workflows/`: CI/CD 변경 전 알림

## Common Verification
- Narrowest fast check: npm run lint
- Broader check: npm run build && npm test
- Runtime smoke check: npm run dev & sleep 5 && curl http://localhost:3000/health

## Operator Notes
- Prefer plain-language explanation when proposing changes? yes
- Prefer options before implementation for open-ended work? yes

## Current Focus
- 사용자 인증 플로우 안정화
- 모바일 반응형 디자인
```

### 3.4 --force 옵션

이미 `.claude/manifest.json`이 있으면 기본적으로 거부됩니다:

```bash
~/claude-code-setup/scripts/init-project.sh /path/to/project
# Error: .claude/manifest.json already exists. Use --force to overwrite.
```

덮어쓰려면:
```bash
~/claude-code-setup/scripts/init-project.sh /path/to/project --force
```

### 3.5 project-profile.md 커스터마이징

자동 생성 후, 프로젝트에 맞게 수정하세요. Frontmatter를 프로젝트별로 조정:

```yaml
---
verification:
  install: "make install"                          # ← 수정 가능
  fast_check: "make lint"
  full_check: "make test"
  smoke_check: "make run &"                        # ← 추가 가능
managed_by: claude-code-setup
blueprint: "generic"
last_machine: "air"
last_session: "2026-04-09T10:30:00Z"
---
```

마크다운 섹션도 프로젝트 문화에 맞게 작성하세요.

### 3.6 프로젝트 설정 버전 관리

`.claude/` 디렉토리를 Git에 커밋하면 팀과 머신 간 설정이 동기화됩니다:

```bash
cd /your/project
git add .claude/manifest.json .claude/project-profile.md
git commit -m "Add Claude Code setup configuration"
git push
```

다른 머신에서:
```bash
git clone ...
cd /project
# .claude 설정이 이미 있음 — init-project.sh 불필요
```

---

## 4. Shell 별칭 사용법

### 4.1 `cl` — 기본 실행 (안전 모드)

기본 Claude Code 실행으로, 안전하게 자동화된 작업 진행:

```bash
cl 버그 수정해줘
cl API 문서 작성
cl 테스트 추가해줘
```

**프롬프트** (자동 추가):
> "작업은 최대한 자동으로 진행하되, 큰 파일 삭제나 다수 파일 삭제는 먼저 확인하고 진행해줘."

**사용 시기**:
- 명확한 작업이 있을 때
- 자동화를 원할 때
- 큰 삭제는 미리 확인받고 싶을 때

**예시**:
```bash
# 터미널에서 입력
cl "test 폴더에 user.test.ts 추가"

# tmux 밖에서 실행하면:
# 1. cl-your-project 세션 자동 생성
# 2. Claude Code 자동 실행
# 3. SSH 끊겨도 tmux 세션 유지 → reattach 가능
```

### 4.2 `clp` — 제안 모드 (3안 구조)

구현 전에 3가지 선택지를 제시합니다.

```bash
clp 이 함수 리팩토링해줘
clp DB 마이그레이션 전략
clp UI 컴포넌트 구조 개선
```

**자동 프롬프트 구조**:
```
작업은 최대한 자동으로 진행하되, 큰 파일 삭제나 다수 파일 삭제는 먼저 확인하고 진행해줘.

먼저 바로 구현하지 말고 아래 형식으로만 짧게 제안해줘.
1. 현재 이해 - 내가 이해한 목표, 영향 범위
2. 선택지 - 1안: 최소 변경안, 2안: 기본 추천안, 3안: 확장안
3. 쉬운 설명 - 각 안이 실제로 무엇을 의미하는지
4. 장단점 - 각 안의 얻는 점과 비용 또는 위험
5. 추천 - 딱 1개의 추천안과 이유
6. 짧게 답할 것 - 질문은 최대 3개, 1/2/3처럼 짧게 고를 수 있게

내가 고르면 그다음 구현으로 넘어가줘.

작업 지시: ...
```

**사용 시기**:
- 여러 방법이 가능할 때
- 결정을 먼저 하고 구현하고 싶을 때
- 리뷰어 역할을 할 때

**예시**:
```bash
clp 에러 핸들링 방식 개선
# 응답: 1. 목표 확인, 2. 3가지 방법, 3. 각 설명, 4. 장단점, 5. 추천, 6. "1/2/3?"
# 사용자가 "2" 입력 → 실행 시작
```

### 4.3 `clr` — 리뷰 모드

코드 변경 없이 검토만 수행합니다.

```bash
clr
# PR 본문 입력 또는 코드 제시

clr 이 변경 위험 요소 체크해줘
```

**프롬프트** (자동 추가):
> "코드 변경은 하지 말고, 삭제 위험, 회귀 가능성, 누락 테스트만 리뷰해줘"

**사용 시기**:
- 코드 리뷰 (변경 없이)
- 병합 전 검토
- PR 분석
- 보안 검토

**예시**:
```bash
clr
# 여기서 PR diff 또는 코드 붙여넣기
# Claude Code가 검토만 수행 (변경 안 함)
```

### 4.4 `clf` — 피드백 캡처

Claude Code 제안에 대한 피드백을 기록합니다. 이 데이터는 향후 개선에 활용됩니다.

```bash
clf 5 helpful clear
clf 4 helpful mixed "응답 속도 느림"
clf 2 not_helpful unclear
```

**문법**:
```bash
clf <만족도> <도움도> <명확도> [추가_의견...]
```

| 인자 | 값 | 설명 |
|------|-----|------|
| 만족도 | 1-5 | 얼마나 만족했는가 (1=최악, 5=최고) |
| 도움도 | helpful / neutral / not_helpful | 도움이 되었나 |
| 명확도 | clear / mixed / unclear | 설명이 명확한가 |
| 추가 의견 | 문자열 | 선택사항 (공백 포함 가능) |

**예시**:
```bash
clf 5 helpful clear
clf 3 neutral mixed "더 구체적이었으면 좋겠음"
clf 1 not_helpful unclear "완전히 다른 방향"
clf 4 helpful clear "좋지만 한국어 설명도 있으면 좋겠음"
```

**저장 위치**:
```bash
~/.claude/feedback/2026-04.jsonl  # 월별로 관리
```

**JSONL 형식**:
```json
{"ts":"2026-04-09T10:30:00Z","satisfaction":5,"helpfulness":"helpful","clarity":"clear","comment":""}
{"ts":"2026-04-09T10:35:15Z","satisfaction":4,"helpfulness":"helpful","clarity":"mixed","comment":"응답 속도 느림"}
```

### 4.5 `cli` — 직접 실행

Claude Code를 직접 호출합니다 (별칭 래퍼 없음).

```bash
cli --help
cli --version
cli "작업 지시"
```

**언제 사용**:
- 기본 Claude Code 옵션 사용
- 커스텀 프롬프트 없이 실행
- 별칭의 자동 프롬프트 우회

---

## 5. tmux 자동 래핑 (핵심 신규 기능!)

### 5.1 무엇인가?

Claude Code를 터미널 밖에서 실행할 때, 자동으로 tmux 세션을 생성합니다. SSH 끊겨도 작업이 유지되므로 모바일이나 이동 중 개발이 훨씬 편합니다.

### 5.2 동작 방식

**시나리오 1: tmux 밖에서 실행**
```bash
# 일반 터미널에서 (tmux 세션 없음)
$ cl "API 엔드포인트 추가"

# 내부 동작:
# 1. _cl_tmux_wrap 함수 확인
# 2. tmux 밖인지 확인 (TMUX 환경변수 없음)
# 3. "cl-<현재_폴더명>" 세션 자동 생성
# 4. tmux new-session -A -s cl-your-project
# 5. Claude Code 자동 실행
```

**시나리오 2: tmux 안에서 실행**
```bash
# tmux 세션 내에서
tmux$ cl "API 엔드포인트 추가"

# 내부 동작:
# 1. TMUX 환경변수 감지
# 2. tmux 래핑 스킵 (return 1)
# 3. 직접 실행 (중첩 방지)
```

**시나리오 3: tmux 미설치 시**
```bash
$ cl "작업"

# 내부 동작:
# 1. tmux 명령어 확인 실패
# 2. Graceful fallback
# 3. 직접 실행 (에러 없음)
```

### 5.3 SSH를 통한 원격 작업

**이동 중 MacBook에서 집 스튜디오 접속**:

```bash
# 모바일 SSH 접속 (Blink, Termius, 기본 터미널 등)
$ ssh studio
studio$ pwd
/Users/leesangmin/projects/salpim-web

# cl 실행 → tmux 세션 자동 생성
studio$ cl "캐시 버그 수정"

# 세션 백그라운드 실행 (SSH 끊겨도 유지)
# [detached from session cl-salpim-web]

# 나중에 SSH 재접속
$ ssh studio
studio$ tmux attach -t cl-salpim-web
# 작업이 그대로 진행 중!
```

### 5.4 비활성화 방법

```bash
# 한 번만 비활성화
CL_NO_TMUX=1 cl "작업"

# 세션 전체 비활성화
export CL_NO_TMUX=1
cl "작업1"
cl "작업2"
unset CL_NO_TMUX
```

또는 zsh 설정에 추가:
```bash
# ~/.zshrc에 추가
export CL_NO_TMUX=1
```

### 5.5 cmux와의 연동

`cmux` 앱에서 작업하는 경우:

```bash
# cmux에서 여러 머신 관리
cms          # studio 세션
cma          # air 세션
cmp          # pro 세션

# cms로 studio 접속
# studio$ cl "작업"
# → 자동으로 cl-<프로젝트명> 세션 생성
# → SSH 끊겨도 유지
```

### 5.6 세션 관리

```bash
# 활성 세션 목록
tmux list-sessions

# 특정 세션 재접속
tmux attach -t cl-your-project

# 세션 강제 종료
tmux kill-session -t cl-your-project

# 모든 cl-* 세션 보기
tmux list-sessions | grep "^cl-"
```

---

## 6. 파괴적 명령어 차단

### 6.1 차단되는 명령어 (6가지 패턴)

| 명령어 | 패턴 | 이유 |
|--------|------|------|
| `rm -rf` | 와일드카드, ./,  .., home, root, 명령어 치환 | 대량 삭제 방지 |
| `find ... -delete` | 모든 find -delete | 재귀 삭제 방지 |
| `git clean -fdx` | -f, -d, -x 포함 | 커밋되지 않은 파일 대량 삭제 |
| `git reset --hard` | 모든 git reset --hard | 작업 손실 방지 |
| `rsync --delete` | --delete 포함 | 백업 실수 방지 |
| `xargs rm` | xargs와 rm 조합 | 파이프 삭제 방지 |

**차단 예시**:
```bash
# Claude Code 내에서 시도
rm -rf ./*
# Error: Blocked bulk rm command targeting wildcard, 
# current directory, home, root, or command-expanded paths. 
# This Claude Code profile is configured to prevent unattended mass deletion.
```

### 6.2 왜 차단하는가

Claude Code는 자동 모드로 실행 중이므로, 사람이 확인하지 않은 대량 삭제를 방지하기 위함입니다. 실수로 인한 데이터 손실 방지.

### 6.3 의도적으로 삭제하려면

#### 방법 1: 수동 모드 사용 (권장)

```bash
# Claude Code 외부에서 수동 모드 실행
claude --permission-mode manual
# 또는
claude-code --permission-mode manual

# 그 후 필요한 명령어 실행 (각각 허락 필요)
rm -rf src/old-feature/
git reset --hard HEAD~3
```

#### 방법 2: 훅 일시 비활성화

settings.json에서 훅 주석 처리:
```json
{
  "hooks": {
    "PreToolUse": [
      // 임시로 주석 처리
      // {
      //   "matcher": "Bash",
      //   "hooks": [
      //     {
      //       "type": "command",
      //       "command": "python3 ~/.claude/hooks/deny-destructive-commands.py"
      //     }
      //   ]
      // }
    ]
  }
}
```

그 후:
```bash
claude "작업"
# 차단 없이 실행
```

#### 방법 3: 안전한 대체 방법

```bash
# ❌ rm -rf ./* (차단됨)

# ✓ 방법 1: 단일 경로 삭제 후 반복
rm -rf src/old-feature/
rm -rf tests/legacy-tests/

# ✓ 방법 2: find로 조건부 삭제
find . -maxdepth 1 -mindepth 1 -not -name ".git" -type d -exec rm -rf {} \;

# ✓ 방법 3: 파일 나열 후 수동 삭제
find . -name "*.tmp" -type f  # 먼저 확인
find . -name "*.tmp" -type f -exec rm {} \;  # 확인 후 실행
```

### 6.4 훅 제거

```bash
./scripts/install-hooks.sh --uninstall

# 또는 --dry-run으로 먼저 확인
./scripts/install-hooks.sh --uninstall --dry-run
```

---

## 7. 멀티머신 개발 워크플로 (핵심 사용 시나리오!)

### 7.1 3대 머신 구성 예

```
┌─────────────────────────────────────┐
│ 집 스튜디오 (M4, 상시)               │
│ - salpim-web, sociai-org 개발        │
│ - cmux 서버로 사용                   │
└─────────────────────────────────────┘
           ↑ SSH / Tailscale
           │
    ┌──────┴──────┐
    ↓             ↓
┌─────────────┐ ┌──────────────┐
│ M1 Pro      │ │ M4 Air (이동)│
│ (작업)      │ │ (카페/외출)  │
└─────────────┘ └──────────────┘
```

### 7.2 새 머신에 설치

```bash
# 1. 저장소 클론
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup

# 2. Shell 별칭 설치
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc

# 3. 훅 설치
~/claude-code-setup/scripts/install-hooks.sh

# 4. 프로젝트 초기화 (Git에서 .claude 설정을 받아온 경우 불필요)
cd ~/projects/salpim-web
~/claude-code-setup/scripts/init-project.sh $(pwd)
```

### 7.3 Branch-Aware Handoff (핵심)

머신을 옮길 때는 **현재 브랜치 기준**으로 동기화합니다. `main` 고정이 아닙니다.

#### Handoff 전 (보내는 쪽)

```bash
git status --short              # 남은 변경사항 확인
git branch --show-current       # 현재 브랜치 확인 (예: feature/login-fix)
git push origin <current-branch>  # 현재 브랜치를 원격에 푸시
```

#### Handoff 후 (받는 쪽)

```bash
git fetch origin                              # 원격 최신 정보 가져오기 (작업 파일은 안 바뀜, 안전한 "먼저 보기")
git switch <current-branch>                   # 이어야 할 브랜치로 이동 (예: feature/login-fix)
git pull --ff-only origin <current-branch>    # 그 브랜치만 깔끔하게 최신화 (이상한 자동 병합 방지)
```

> **왜 `--ff-only`인가?** fast-forward만 허용해서 예상치 못한 머지 커밋을 막습니다. 충돌이 있으면 실패하므로 초보자에게도 안전합니다.

> **`<current-branch>`는 뭔가?** 방금 `git branch --show-current`로 확인한 브랜치명 그대로입니다. 예: `feature/login-fix`

#### 왜 이게 좋은가

- main 고정보다 실수를 줄입니다
- feature 브랜치 handoff를 안전하게 할 수 있습니다
- "지금 하던 일"을 그대로 다른 Mac에서 이어가게 해줍니다

### 7.4 다른 Mac에서 이어받기 (cmux / wrapper 사용 가능)

Mac 간 이동 시 cmux, SSH wrapper를 자유롭게 사용합니다:

```bash
# cmux로 M4 Studio 접속
cms   # alias for cmux-remote m4-studio

# 또는 Tailscale SSH
ssh studio

# 프로젝트 이동 + handoff 후 명령
cd ~/projects/salpim-web
git fetch origin
git switch <current-branch>
git pull --ff-only origin <current-branch>

# tmux 세션이 남아있으면 재접속
tmux attach -t cl-salpim-web

# 없으면 새로 시작 (cl이 tmux 자동 생성)
cl "이어서 작업"
```

### 7.5 스마트폰에서 이어받기 (plain SSH 전용)

스마트폰에는 codex-setup 저장소나 wrapper가 없습니다.
**plain SSH만** 사용하고, 원격 Mac에 들어가서 상태를 보고 이어받는 것이 핵심입니다.

```bash
# 1. plain SSH로 메인 Mac에 접속
ssh your-main-mac

# 2. 프로젝트 이동
cd /absolute/path/to/project

# 3. 상태 확인 + 브랜치 동기화
git fetch origin
git switch <current-branch>
git pull --ff-only origin <current-branch>

# 4. 작업 이어가기
cl "긴급 수정"
```

**Fallback (가장 단순한 형태):**

```bash
ssh your-main-mac
cd /absolute/path/to/project
cl
```

> 스마트폰 터미널은 최대한 단순해야 실수도 적고 복구도 쉽습니다.
> "원격 Mac에 들어가서 상태만 보고 이어받기"가 핵심입니다.

### 7.6 자동 머신 핸드오프

`cl`/`clp`/`clr` 실행 시 **두 가지가 자동으로** 일어납니다:

#### 1) `[handoff]` 자동 표시

다른 머신에서 같은 프로젝트를 작업한 기록이 있으면 터미널에 표시됩니다:

```bash
$ cl "UI 수정"
[handoff] m4-air → salpim-web (2026-04-09T14:30:00Z, branch: feature-xyz)
  ⚠ dirty: 3파일
  ⚠ unpushed: 2커밋
```

이 정보는 `~/.dev-retrospective/data/machines/` 아래의 `last_session.json`에서 읽습니다. 각 머신의 `session-backup.sh`가 세션 종료 시 자동으로 기록하고, `homelab-orchestration`이 머신 간 동기화합니다.

#### 2) `last_machine` / `last_session` 자동 갱신

`.claude/project-profile.md`가 있으면 현재 머신명과 시각으로 자동 업데이트:

```yaml
last_machine: 'm4-studio'    # ← cl 실행할 때마다 자동 갱신
last_session: '2026-04-09T15:00:00Z'
```

#### 2중 동기화 경로

| 경로 | 동기화 방식 | 시점 | `.claude/` gitignore여도? |
|------|------------|------|--------------------------|
| `dev-retrospective/machines/` | session-backup → homelab-orchestration 자동 push | 세션 종료 | **작동함** (1순위) |
| `.claude/project-profile.md` | cl 실행 시 갱신 → git push로 공유 | cl 실행 | git 동기화 필요 (fallback) |

> `.claude/`가 `.gitignore`에 포함된 프로젝트도 dev-retrospective 경로로 핸드오프가 정상 작동합니다.

#### 전체 흐름 예시

```
Mac A (M4 Studio)에서:
  cl → 작업 → git push origin $(git branch --show-current) → 세션 종료
  → session-backup.sh가 machines/m4-studio/last_session.json 기록
  → homelab-orchestration 자동 commit+push
      ↓
Mac B (M4 Air, cmux/wrapper 사용 가능)에서:
  git fetch origin
  git switch <현재-브랜치>
  git pull --ff-only origin <현재-브랜치>
  cl → [handoff] m4-studio → myproject (시각, branch, dirty/unpushed 표시)
  → last_machine: m4-air로 갱신 → 작업 이어가기
      ↓
스마트폰 (plain SSH 전용)에서:
  ssh studio
  cd ~/projects/myproject
  git fetch origin && git switch <현재-브랜치> && git pull --ff-only origin <현재-브랜치>
  cl → 작업 이어가기
```

### 7.5 한 번에 모든 머신에 설치

```bash
for machine in studio air pro; do
  ssh "$machine" '
    git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
    ~/claude-code-setup/scripts/install-shell-integration.sh
    ~/claude-code-setup/scripts/install-hooks.sh
    source ~/.zshrc
  '
done
```

### 7.8 settings.json 동기화 전략

**권장**: settings.json은 머신별로 **독립적으로 유지**합니다 (로컬 설정이므로).

```bash
# 훅만 동기화
cd ~/claude-code-setup
git pull
cp hooks/deny-destructive-commands.py ~/.claude/hooks/

# 또는 스크립트 재실행
./scripts/install-hooks.sh
```

---

## 8. 피드백 시스템

### 8.1 clf 명령어 사용법

Claude Code 제안에 대한 피드백을 기록합니다.

```bash
clf <만족도:1-5> <도움도> <명확도> [추가_의견...]
```

**예시**:
```bash
clf 5 helpful clear
clf 4 helpful mixed "약간 느림"
clf 2 not_helpful unclear "완전 다른 방향"
```

### 8.2 피드백 저장 구조

```bash
~/.claude/feedback/
├── 2026-04.jsonl  # 월별 파일
├── 2026-05.jsonl
└── ...
```

각 줄은 JSONL 형식:
```json
{"ts":"2026-04-09T10:30:00Z","satisfaction":5,"helpfulness":"helpful","clarity":"clear","comment":""}
```

### 8.3 피드백 분석

```bash
# 최근 피드백 보기
tail -20 ~/.claude/feedback/2026-04.jsonl

# 만족도 평균 계산
cat ~/.claude/feedback/*.jsonl | jq '.satisfaction' | awk '{sum+=$1} END {print sum/NR}'

# helpful 비율
cat ~/.claude/feedback/*.jsonl | jq '.helpfulness' | grep -c helpful
```

---

## 9. OMC 연동

### 9.1 검증 모듈과의 통합

`.claude/project-profile.md`의 Frontmatter는 oh-my-claudecode의 **verification module**이 자동으로 읽습니다.

```yaml
---
verification:
  install: "npm install"
  fast_check: "npm run lint"
  full_check: "npm run build && npm test"
  smoke_check: "npm run dev & sleep 5 && curl http://localhost:3000/health"
---
```

### 9.2 OMC에서 자동 검증

OMC의 ralph, autopilot, ultrawork 등이 작업 후 자동으로 다음을 실행합니다:

```
1. verification.install    — 의존성 설치
   ↓
2. verification.fast_check — 빠른 검증 (lint, 일부 테스트)
   ↓
3. verification.full_check — 전체 검증 (build, 모든 테스트)
   ↓
4. verification.smoke_check — 런타임 검증
```

**예**: 기능 추가 후
```bash
cl "API 엔드포인트 추가해줘"

# OMC 내부 검증 체인:
# 1. npm install ✓
# 2. npm run lint ✓
# 3. npm run build && npm test ✓
# 4. curl http://localhost:3000/health ✓

# 모든 검증 통과 → "작업 완료" 선언
```

### 9.3 AGENTS.md 생성

프로젝트 초기화 후, OMC의 `deepinit`으로 계층적 AGENTS.md 생성:

```bash
cd /your/project
/oh-my-claudecode:deepinit

# 결과:
# AGENTS.md — 코드베이스 구조 분석 완료
#   - 파일 계층도
#   - 핵심 컴포넌트
#   - API 엔드포인트
#   - 의존성 맵
```

### 9.4 verification 명령어 테스트

OMC 연동 전에 검증 명령어가 제대로 작동하는지 확인:

```bash
cd /your/project

# install 테스트
npm install

# fast_check 테스트
npm run lint

# full_check 테스트
npm run build && npm test

# smoke_check 테스트 (있는 경우)
npm run dev & sleep 5 && curl http://localhost:3000/health; pkill -f "npm run dev"
```

---

## 10. FAQ / 문제 해결

### Q1: 설치 후 `cl` 명령어를 찾을 수 없습니다

**A**: `source ~/.zshrc`를 실행하세요.

```bash
source ~/.zshrc
cl --help

# 또는 새 터미널 탭을 열어서 .zshrc 자동 로드
```

### Q2: tmux 래핑이 작동하지 않습니다

**A**: 다음을 확인하세요:

```bash
# 1. tmux 설치 확인
which tmux

# 설치 안 됨 → brew install tmux

# 2. TMUX 환경변수 확인
echo $TMUX
# 비어있으면 tmux 밖 (정상)

# 3. CL_NO_TMUX 설정 확인
echo $CL_NO_TMUX
# 비어있으면 정상 (설정 안 됨)

# 4. 테스트
cl "echo test"
# cl-your-project 세션 생성됨?
tmux list-sessions
```

### Q3: 훅이 작동하지 않습니다

**A**: settings.json 설정을 확인하세요.

```bash
# 설정 확인
cat ~/.claude/settings.json | grep -A 10 "PreToolUse"

# 훅 스크립트 존재 여부
ls -la ~/.claude/hooks/deny-destructive-commands.py

# 훅 권한 확인
chmod +x ~/.claude/hooks/deny-destructive-commands.py

# 훅 직접 테스트
echo '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' | \
  python3 ~/.claude/hooks/deny-destructive-commands.py

# 차단된 명령어 테스트
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf ./*"}}' | \
  python3 ~/.claude/hooks/deny-destructive-commands.py
# 거부(deny) 응답 나옴?
```

### Q4: `init-project.sh`가 블루프린트를 잘못 감지했습니다

**A**: `--force` 옵션으로 다시 실행한 후 Frontmatter 수정하세요.

```bash
~/claude-code-setup/scripts/init-project.sh /path/to/project --force

# project-profile.md Frontmatter 수정
nano .claude/project-profile.md

# 예: 실제로는 generic
---
blueprint: "generic"  # ← 수정
verification:
  install: "make install"
  fast_check: "make lint"
  full_check: "make test"
  smoke_check: ""
---
```

### Q5: 프로젝트마다 다른 검증 명령이 필요합니다

**A**: 각 프로젝트의 `.claude/project-profile.md` Frontmatter를 커스터마이징하세요.

```bash
# 프로젝트 A (npm)
cd ~/projects/project-a
cat .claude/project-profile.md | head -10
# npm install, npm run lint, npm run build && npm test

# 프로젝트 B (Python)
cd ~/projects/project-b
cat .claude/project-profile.md | head -10
# pip install -e ., python -m pytest -x, python -m pytest

# 프로젝트 C (custom)
cd ~/projects/project-c
nano .claude/project-profile.md
---
verification:
  install: "make install"
  fast_check: "make lint"
  full_check: "make test"
  smoke_check: "make run &"
---
```

### Q6: 여러 머신에서 settings.json 동기화하려면?

**A**: settings.json은 보안상 머신별로 유지하는 것을 권장합니다. 훅만 동기화하세요:

```bash
# 마스터 머신에서 훅 업데이트
cd ~/claude-code-setup
git add hooks/deny-destructive-commands.py
git commit -m "Update safety hooks"
git push

# 다른 머신에서
cd ~/claude-code-setup
git pull
cp hooks/deny-destructive-commands.py ~/.claude/hooks/
```

### Q7: 파괴적 명령어를 의도적으로 실행해야 하는데요?

**A**: 세 가지 방법이 있습니다:

**1. 수동 모드 사용 (권장)**:
```bash
claude --permission-mode manual
rm -rf src/old-feature/  # 허락 필요
```

**2. 훅 일시 비활성화**:
settings.json에서 PreToolUse 훅 주석 처리 → 재로드

**3. 안전한 대체**:
```bash
# 단일 경로 삭제 반복
rm -rf src/old-feature/
rm -rf tests/legacy-tests/

# find로 조건부 삭제
find . -name "*.tmp" -delete
```

### Q8: 여러 프로젝트 간 project-profile.md를 동기화하려면?

**A**: 공통 템플릿을 조직 저장소에 유지하세요.

```bash
# organization-setup 저장소 구조
templates/
└── standard-project-profile.md (웹앱용)

# 각 프로젝트에서
cp ~/org-setup/templates/standard-project-profile.md .claude/project-profile.md
# 프로젝트별 커스터마이징
```

### Q9: 스크립트 에러: "set -euo pipefail"

**A**: bash로 실행해야 합니다.

```bash
# ❌ 틀림
sh ./scripts/init-project.sh /path

# ✓ 맞음
bash ./scripts/init-project.sh /path

# ✓ shebang 사용
./scripts/init-project.sh /path

# ✓ zsh에서도 가능
./scripts/init-project.sh /path
```

### Q10: 롤백하려면?

**A**: 간단합니다:

```bash
# 1. Shell 별칭 제거
nano ~/.zshrc
# ">>> claude-code-setup >>>" 부터 "<<< claude-code-setup <<<" 까지 삭제
source ~/.zshrc

# 2. 훅 제거
./scripts/install-hooks.sh --uninstall

# 또는 수동 제거
rm ~/.claude/hooks/deny-destructive-commands.py
nano ~/.claude/settings.json
# PreToolUse 블록 삭제

# 3. 저장소 제거
rm -rf ~/claude-code-setup

# 4. 프로젝트의 .claude/ 디렉토리는 유지하려면 남겨두기
ls ~/.claude/projects/your-project/
```

### Q11: tmux 세션이 남겨집니다

**A**: 세션을 명시적으로 종료하세요.

```bash
# 활성 세션 보기
tmux list-sessions

# 특정 세션 종료 (깔끔하게)
tmux kill-session -t cl-your-project

# 모든 cl-* 세션 종료
for session in $(tmux list-sessions | grep "^cl-" | cut -d: -f1); do
  tmux kill-session -t "$session"
done

# 또는 tmux 완전 종료
tmux kill-server
```

### Q12: 여러 프로젝트를 한 tmux 세션에서 관리하려면?

**A**: tmux window를 수동으로 생성하세요.

```bash
# 메인 세션 시작
tmux new-session -s main -c ~/projects/project-a

# 프로젝트 변경 후 새 window 추가
tmux new-window -t main -c ~/projects/project-b -n "project-b"
tmux new-window -t main -c ~/projects/project-c -n "project-c"

# 세션 확인
tmux list-windows -t main

# 이동
tmux select-window -t main:project-b
```

---

## 11. 빠른 참고

### 한 번에 모든 머신에 설치

```bash
for machine in studio air pro; do
  ssh "$machine" '
    git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
    ~/claude-code-setup/scripts/install-shell-integration.sh
    ~/claude-code-setup/scripts/install-hooks.sh
    source ~/.zshrc
  '
done
```

### 프로젝트 빠른 설정

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
~/claude-code-setup/scripts/init-project.sh "$PROJECT_ROOT"
git add "$PROJECT_ROOT/.claude/"
git commit -m "Add Claude Code setup configuration"
git push
```

### 모든 프로젝트 재초기화

```bash
for proj in ~/projects/*; do
  [ -d "$proj" ] && ~/claude-code-setup/scripts/init-project.sh "$proj" --force
done
```

### 모든 프로젝트 검증 명령 테스트

```bash
for proj in ~/projects/*; do
  [ -d "$proj" ] && {
    echo "Testing: $proj"
    cd "$proj"
    
    # project-profile.md에서 검증 명령 읽기
    install=$(grep "install:" .claude/project-profile.md | sed "s/.*install: '//;s/'//")
    
    if [ -n "$install" ]; then
      echo "  Running: $install"
      eval "$install"
    fi
  }
done
```

---

## 12. 참고 자료

- [원본 codex-setup 저장소](https://github.com/nori00000/codex-setup)
- [oh-my-claudecode 공식 문서](https://github.com/oh-my-claudecode/oh-my-claudecode)
- [Claude Code 공식 가이드](https://claude.com/code)
- [tmux 공식 매뉴얼](https://man.openbsd.org/tmux)

---

## 13. 변경 이력

### v1.0 (2026-04-09)

**신규 기능**:
- tmux 자동 래핑 (SSH 세션 유지)
- `last_machine`, `last_session` 필드 추가
- `install-hooks.sh` 스크립트화 (--dry-run, --uninstall)
- 모든 파일 사용 예시 추가

**개선**:
- 멀티머신 워크플로우 상세 설명
- 한국어 전체 작성
- 복사-붙여넣기 가능한 명령어 위주
