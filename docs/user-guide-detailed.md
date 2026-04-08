# Claude Code Setup 상세 사용 가이드

## 1. 개요

**Claude Code Setup**은 Codex Setup에서 포팅된 프로젝트로, Claude Code 멀티머신 환경에서 저마찰(low-friction) 기본값을 제공하는 도구 모음입니다.

### 이 프로젝트가 필요한 이유

- **자동화된 안전**: 파괴적 명령어(rm -rf, git reset --hard 등) 자동 차단
- **프로젝트 프로필**: 각 프로젝트의 검증 명령, 우선값, 보호 영역을 선언
- **멀티머신 동기화**: 집 스튜디오, 이동 MacBook 간 일관된 설정 유지
- **OMC 연동**: oh-my-claudecode 검증 모듈과의 통합

### 포함 내용

| 파일 | 용도 |
|------|------|
| `hooks/deny-destructive-commands.py` | Claude Code PreToolUse 훅 — 위험한 명령어 차단 |
| `scripts/install-shell-integration.sh` | zsh 별칭 설치 (cl/clp/clr/clf/cli) |
| `scripts/init-project.sh` | 프로젝트 초기화 — manifest.json, project-profile.md 생성 |
| `templates/project-profile.md` | 프로젝트 프로필 템플릿 |
| `templates/manifest.schema.json` | manifest.json의 JSON Schema |

---

## 2. 설치 방법

### 2.1 저장소 클론

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
cd ~/claude-code-setup
```

### 2.2 Shell 별칭 설치

zsh에 cl/clp/clr/clf/cli 별칭을 추가합니다.

```bash
./scripts/install-shell-integration.sh
source ~/.zshrc
```

**확인**:
```bash
cl --help  # 작동하면 설치 완료
```

**기존 cc() 함수 충돌 시**: 스크립트가 자동으로 감지하고 cl 접두사를 사용합니다.

### 2.3 파괴적 명령어 차단 훅 설치

#### 옵션 A: 자동 설치 (권장)

```bash
cp ~/claude-code-setup/hooks/deny-destructive-commands.py ~/.claude/hooks/
```

#### 옵션 B: 수동 설치

1. 훅 파일 복사:
```bash
mkdir -p ~/.claude/hooks
cp ~/claude-code-setup/hooks/deny-destructive-commands.py ~/.claude/hooks/
```

2. Claude Code settings.json에 훅 등록:
```bash
# macOS
open ~/.claude/settings.json

# Linux/SSH
nano ~/.claude/settings.json
```

3. `hooks` 섹션 추가 또는 수정:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "tool": "Bash",
        "script": "~/.claude/hooks/deny-destructive-commands.py"
      }
    ]
  }
}
```

**확인**:
```bash
# Claude Code 내에서 시도하면 차단됨
rm -rf ./*
# Error: Blocked bulk rm command targeting wildcard...
```

---

## 3. 프로젝트 초기화

프로젝트당 **한 번만** 실행합니다.

```bash
~/claude-code-setup/scripts/init-project.sh /절대경로/your-project
```

### 3.1 블루프린트 자동 감지

스크립트가 프로젝트 유형을 자동으로 감지합니다:

| 감지 기준 | 블루프린트 | 검증 명령 |
|----------|-----------|---------|
| `package.json` 있음 | **web-app** | npm install, npm run lint/test, npm run build && npm test |
| `pyproject.toml` / `setup.py` / `requirements.txt` | **python-service** | pip install -e ., python -m pytest -x, python -m pytest |
| 둘 다 없음 | **generic** | (검증 명령 미지정) |

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

생성된 프로필은 YAML frontmatter + 마크다운으로 구성:

```yaml
---
# ← OMC verification module이 읽는 부분
verification:
  install: "npm install"
  fast_check: "npm run lint"
  full_check: "npm run build && npm test"
  smoke_check: ""
managed_by: claude-code-setup
blueprint: web-app
---
```

### 3.4 --force 옵션

이미 `.claude/manifest.json`이 있으면 기본적으로 거부됩니다:

```bash
./scripts/init-project.sh /path/to/project
# Error: .claude/manifest.json already exists. Use --force to overwrite.
```

덮어쓰려면:
```bash
./scripts/init-project.sh /path/to/project --force
```

### 3.5 project-profile.md 커스터마이징

자동 생성 후, 프로젝트에 맞게 수정하세요:

```yaml
---
verification:
  install: "npm install"                          # ← 수정 가능
  fast_check: "npm run lint"
  full_check: "npm run build && npm test"
  smoke_check: "npm run dev &"                    # ← 추가
managed_by: claude-code-setup
blueprint: web-app
---
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
- Runtime smoke check: npm run dev & sleep 5 && curl http://localhost:3000/api/health

## Operator Notes
- Prefer plain-language explanation when proposing changes? yes
- Prefer options before implementation for open-ended work? yes

## Current Focus
- 사용자 인증 플로우 안정화
- 모바일 반응형 디자인
```

**Frontmatter 수정 팁**:
- `verification.install`: 의존성 설치 명령 (pip install, npm install 등)
- `verification.fast_check`: 가장 빠른 검증 (lint, 빠른 테스트 서브셋)
- `verification.full_check`: 전체 검증 (build + 모든 테스트)
- `verification.smoke_check`: 런타임 검증 (서버 시작 테스트 등)

---

## 4. Shell 별칭 사용법

### 4.1 `cl` — 기본 실행 (안전 모드)

기본 Claude Code 실행으로, 안전하게 자동화된 작업 진행:

```bash
cl 버그 수정해줘
cl API 문서 작성
cl 테스트 추가해줘
```

프롬프트:
> "작업은 최대한 자동으로 진행하되, 큰 파일 삭제나 다수 파일 삭제는 먼저 확인하고 진행해줘."

**사용 시기**:
- 명확한 작업이 있을 때
- 자동화를 원할 때
- 큰 삭제는 미리 확인받고 싶을 때

### 4.2 `clp` — 제안 모드 (3안 구조)

구현 전에 3가지 선택지를 제시합니다.

```bash
clp 이 함수 리팩토링해줘
clp DB 마이그레이션 전략
clp UI 컴포넌트 구조 개선
```

프롬프트:
```
1. 현재 이해 — 목표와 영향 범위
2. 선택지 — 1안: 최소 변경, 2안: 기본 추천, 3안: 확장안
3. 쉬운 설명 — 각 안이 실제로 무엇을 의미하는지
4. 장단점 — 각 안의 장점, 비용, 위험
5. 추천 — 1개 추천과 이유
6. 짧게 답할 것 — 질문 최대 3개, 1/2/3처럼 선택 가능
```

**사용 시기**:
- 여러 방법이 가능할 때
- 결정을 먼저 하고 구현하고 싶을 때
- 리뷰어 역할을 할 때

### 4.3 `clr` — 리뷰 모드

코드 변경 없이 검토만 수행합니다.

```bash
clr
# PR 본문 입력 또는 코드 제시

clr 이 변경 위험 요소 체크해줘
```

프롬프트:
> "코드 변경은 하지 말고, 삭제 위험, 회귀 가능성, 누락 테스트만 리뷰해줘"

**사용 시기**:
- 코드 리뷰 (변경 없이)
- 병합 전 검토
- PR 분석

### 4.4 `clf` — 피드백 캡처

Claude Code 제안에 대한 피드백을 기록합니다.

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
| 만족도 | 1-5 | 얼마나 만족했는가 |
| 도움도 | helpful / neutral / not_helpful | 도움이 되었나 |
| 명확도 | clear / mixed / unclear | 설명이 명확한가 |
| 추가 의견 | 문자열 | 선택사항 |

**예**:
```bash
clf 5 helpful clear
clf 3 neutral mixed "더 구체적이었으면 좋겠음"
clf 1 not_helpful unclear "완전히 다른 방향"
```

### 4.5 `cli` — 직접 실행

Claude Code를 직접 호출합니다 (별칭 없음).

```bash
cli --help
cli --version
cli "작업 지시"
```

---

## 5. 파괴적 명령어 차단

### 5.1 차단되는 명령어

| 명령어 | 패턴 | 이유 |
|--------|------|------|
| `rm -rf` | 와일드카드, 현재/상위 디렉토리, home, root 포함 | 대량 삭제 방지 |
| `find ... -delete` | 모든 find -delete | 재귀 삭제 방지 |
| `git clean -fdx` | -f, -d, -x 포함 | 커밋되지 않은 파일 대량 삭제 |
| `git reset --hard` | 모든 git reset --hard | 작업 손실 방지 |
| `rsync --delete` | --delete 포함 | 백업 실수 방지 |
| `xargs rm` | xargs와 rm 조합 | 파이프 삭제 방지 |

### 5.2 왜 차단하는가

Claude Code는 자동 모드로 실행 중이므로, 사람이 확인하지 않은 대량 삭제를 방지하기 위함입니다.

### 5.3 의도적으로 삭제하려면

**방법 1: 수동 세션 사용**

```bash
# Claude Code 내에서 "--permission-mode manual" 사용
claude --permission-mode manual
# 그 후 필요한 명령어 실행 (각각 허락 필요)
```

**방법 2: 훅 일시 비활성화**

settings.json에서 훅 주석 처리:
```json
{
  "hooks": {
    "PreToolUse": [
      // 임시로 주석 처리
      // {
      //   "tool": "Bash",
      //   "script": "~/.claude/hooks/deny-destructive-commands.py"
      // }
    ]
  }
}
```

**방법 3: 안전한 대체 방법**

```bash
# ❌ rm -rf ./* (차단됨)
# ✓ find . -maxdepth 1 -mindepth 1 -not -name ".git" -exec rm -rf {} \;
# ✓ 단일 파일 삭제 후 반복
rm -rf src/old-feature/
rm -rf tests/legacy-tests/
```

---

## 6. 다른 머신에 세팅하기

### 6.1 3대 머신 동기화 개요

| 머신 | 설정 |
|------|------|
| 집 스튜디오 (상시) | 마스터 설정 |
| MacBook Air (이동) | 동기화 필요 |
| MacBook Pro (작업) | 동기화 필요 |

### 6.2 새 머신에 설치

```bash
# 1. 저장소 클론
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup

# 2. Shell 별칭 설치
~/claude-code-setup/scripts/install-shell-integration.sh
source ~/.zshrc

# 3. 훅 설치
mkdir -p ~/.claude/hooks
cp ~/claude-code-setup/hooks/deny-destructive-commands.py ~/.claude/hooks/

# 4. settings.json에 훅 등록 (2.3절 참고)
open ~/.claude/settings.json
# 또는
nano ~/.claude/settings.json
```

### 6.3 프로젝트 설정 동기화

각 프로젝트에서:

```bash
cd /your/project/path
~/claude-code-setup/scripts/init-project.sh $(pwd)
```

또는 기존 설정을 덮어쓰려면:

```bash
~/claude-code-setup/scripts/init-project.sh $(pwd) --force
```

### 6.4 .claude 디렉토리 깃 커밋

프로젝트 `.claude/` 디렉토리를 Git 리포에 커밋하면 팀/머신 간 설정이 동기화됩니다:

```bash
cd /your/project/path
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

## 7. OMC 연동

### 7.1 검증 모듈과의 통합

`.claude/project-profile.md`의 frontmatter는 oh-my-claudecode의 **verification module**이 읽습니다.

```yaml
---
verification:
  install: "npm install"
  fast_check: "npm run lint"
  full_check: "npm run build && npm test"
  smoke_check: "npm run dev & sleep 5 && curl http://localhost:3000/health"
---
```

### 7.2 OMC에서 자동 검증

OMC의 ralph, autopilot, ultrawork 등이 작업 후 자동으로 다음을 실행합니다:

1. `verification.install` — 의존성 설치
2. `verification.fast_check` — 빠른 검증 (lint, 일부 테스트)
3. `verification.full_check` — 전체 검증 (build, 모든 테스트)
4. `verification.smoke_check` — 런타임 검증

**예**: 기능 추가 후
```bash
cl API 엔드포인트 추가해줘
# OMC 내부 검증:
# 1. npm install ✓
# 2. npm run lint ✓
# 3. npm run build && npm test ✓
# 4. curl http://localhost:3000/health ✓
```

### 7.3 AGENTS.md 생성

`init-project.sh` 완료 후, OMC의 deepinit으로 AGENTS.md 생성:

```bash
cd /your/project
/oh-my-claudecode:deepinit
```

이는 자동으로 코드베이스 구조를 분석하여 계층적 AGENTS.md를 생성합니다.

---

## 8. FAQ / 문제 해결

### Q1: 설치 후 `cl` 명령어를 찾을 수 없습니다

**A**: `source ~/.zshrc`를 실행하세요.

```bash
source ~/.zshrc
cl --help
```

또는 새 터미널 탭을 엽니다.

### Q2: 훅이 작동하지 않습니다

**A**: settings.json을 확인하세요.

```bash
cat ~/.claude/settings.json | grep -A 5 "PreToolUse"
```

훅 경로가 정확해야 합니다:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "tool": "Bash",
        "script": "~/.claude/hooks/deny-destructive-commands.py"
      }
    ]
  }
}
```

### Q3: `init-project.sh`가 블루프린트를 잘못 감지했습니다

**A**: `--force` 옵션으로 다시 실행하세요.

```bash
~/claude-code-setup/scripts/init-project.sh /path/to/project --force
```

그 후 `.claude/project-profile.md`의 frontmatter를 수정:

```yaml
---
verification:
  install: "your-custom-install-command"
  fast_check: "your-custom-fast-check"
  full_check: "your-custom-full-check"
  smoke_check: ""
managed_by: claude-code-setup
blueprint: python-service  # ← 여기 수정
---
```

### Q4: 프로젝트마다 다른 검증 명령이 필요합니다

**A**: `.claude/project-profile.md`의 frontmatter를 프로젝트별로 커스터마이징하세요.

```yaml
---
verification:
  install: "make install"
  fast_check: "make lint"
  full_check: "make test"
  smoke_check: "make run &"
managed_by: claude-code-setup
blueprint: generic
---
```

### Q5: 기존 cc() 함수가 있는데 어떻게 되나요?

**A**: 자동으로 감지되어 덮어쓰지 않습니다. `cl` 접두사가 사용됩니다.

```bash
# 기존
cc "작업"

# 추가됨
cl "작업"
clp "작업"
clr "작업"
```

기존 cc() 함수를 대체하려면 수동으로 `.zshrc`를 수정하세요.

### Q6: 여러 머신에서 settings.json 동기화하려면?

**A**: 보안상 settings.json은 머신별로 독립적으로 유지하는 것을 권장합니다. 훅만 동기화하면 됩니다:

```bash
# 마스터 머신에서
git add hooks/deny-destructive-commands.py
git commit -m "Update safety hooks"
git push

# 다른 머신에서
git pull
cp hooks/deny-destructive-commands.py ~/.claude/hooks/
```

### Q7: 파괴적 명령어를 의도적으로 실행해야 하는데요?

**A**: 세 가지 방법이 있습니다:

1. **수동 모드**: `claude --permission-mode manual`에서 실행 (각 명령 허락 필요)
2. **훅 일시 비활성화**: settings.json에서 훅 주석 처리
3. **안전한 대체**: 단일 파일/디렉토리 삭제를 반복

### Q8: 여러 프로젝트 간 project-profile.md를 동기화하려면?

**A**: 공통 템플릿을 프로젝트 저장소에 커밋하세요.

```bash
# organization-wide-setup 저장소
templates/
└── standard-project-profile.md

# 각 프로젝트에서
cp ~/organization-setup/templates/standard-project-profile.md .claude/project-profile.md
# 또는 프로젝트별 커스터마이징
```

### Q9: 스크립트 에러: "set -euo pipefail"

**A**: bash 버전이 오래되었거나 sh로 실행되었을 가능성입니다.

```bash
# ❌
sh ./scripts/init-project.sh /path

# ✓
bash ./scripts/init-project.sh /path
./scripts/init-project.sh /path  # shebang 사용
```

### Q10: 롤백하려면?

**A**: 간단합니다:

```bash
# Shell 별칭 제거
nano ~/.zshrc
# ">>> claude-code-setup >>>" 부터 "<<< claude-code-setup <<<" 까지 삭제

# 훅 제거
rm ~/.claude/hooks/deny-destructive-commands.py

# settings.json에서 훅 블록 제거
nano ~/.claude/settings.json

# 저장소 제거
rm -rf ~/claude-code-setup
```

프로젝트의 `.claude/` 디렉토리는 유지하려면 남겨두세요.

---

## 9. 빠른 참고

### 한 번에 모든 머신에 설치

```bash
for machine in studio air pro; do
  ssh "$machine" '
    git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
    ~/claude-code-setup/scripts/install-shell-integration.sh
    mkdir -p ~/.claude/hooks
    cp ~/claude-code-setup/hooks/deny-destructive-commands.py ~/.claude/hooks/
  '
done
```

### 프로젝트 빠른 설정

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
~/claude-code-setup/scripts/init-project.sh "$PROJECT_ROOT"
git add "$PROJECT_ROOT/.claude/"
git commit -m "Claude Code setup"
```

### 모든 프로젝트 재초기화

```bash
for proj in ~/projects/*; do
  [ -d "$proj" ] && ~/claude-code-setup/scripts/init-project.sh "$proj" --force
done
```

---

## 참고 자료

- [원본 codex-setup 저장소](https://github.com/nori00000/codex-setup)
- [oh-my-claudecode 공식 문서](https://github.com/oh-my-claudecode/oh-my-claudecode)
- [Claude Code 공식 가이드](https://claude.com/code)
