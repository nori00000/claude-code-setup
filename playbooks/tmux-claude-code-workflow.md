# tmux 실전 매뉴얼 (Windows WSL2 + Claude Code / Codex 워크플로우)

> 환경: Windows 11 + WSL2 Ubuntu 26.04 + tmux 3.6 + Claude Code v2.1.x + Codex CLI
> Prefix: **Ctrl+A** (보조: Ctrl+B)
> 작성일: 2026-05-22 / 다음 갱신 권장: AI 도구는 주마다 진화하므로 분기별 재확인
> 대상: tmux 처음 제대로 써보는 사람 + Claude Code/Codex로 생산성 끌어올리고 싶은 사람

---

## 0. 한 줄 요약

**tmux = "터미널 안의 가상 데스크탑"**. PowerShell 창이 꺼져도 안에 돌던 Claude Code/Codex/서버가 계속 살아있고, 나중에 attach해서 그대로 이어 쓸 수 있습니다. 2026년 5월 현재 AI 에이전트 병렬 운영의 외곽 셸 표준이기도 합니다.

핵심 개념 3개:

| 개념 | 뜻 | 비유 |
|---|---|---|
| **Session(세션)** | tmux의 가장 큰 단위. 작업 묶음 하나 | 모니터 한 대 |
| **Window(윈도우)** | 세션 안의 탭 | 모니터 위의 탭 |
| **Pane(팬)** | 윈도우 안의 분할 화면 | 한 탭 안에서 좌우/상하로 쪼갠 영역 |

**Prefix 키** = `Ctrl + A` (이 머신 설정). tmux에게 명령을 내릴 땐 거의 항상 먼저 Ctrl+A를 누르고 손을 뗀 다음 다음 키를 누릅니다. 이 매뉴얼에서 `prefix + d` 라고 쓰면 "Ctrl+A 눌렀다 떼고 → d" 라는 뜻입니다.

> **왜 Ctrl+B가 아니라 Ctrl+A?**
> - tmux 기본 Prefix는 Ctrl+B. 하지만 **Claude Code가 Ctrl+B를 가로채서** tmux로 전달하지 않습니다 (anthropics/claude-code#35936).
> - Ctrl+Space는 한국어 IME(한영 전환)와 충돌 위험이 있습니다.
> - Ctrl+A가 2026 한국 WSL2 + Claude Code 환경의 권장 Prefix. shell의 "줄 시작 이동" 단축키와 약간 겹치지만 prefix는 잠깐 누르고 떼는 키라 실제 충돌은 거의 없습니다.

---

## 1. 첫 설정 (이미 적용된 상태)

이 머신에는 이미 다음이 적용되어 있습니다 (`~/.tmux.conf`):

| 구성 | 값 |
|---|---|
| Prefix | `Ctrl+A` (보조 `Ctrl+B`) |
| Claude Code 필수 3종 | `allow-passthrough on`, `extended-keys on`, `xterm*:extkeys`, `xterm*:sync` |
| 히스토리 | 100000 줄 (AI 출력이 길어서) |
| 마우스 | on |
| 윈도우/팬 번호 | 1부터 시작 |
| tmux 3.6 신기능 | `pane-scrollbars on` |
| 클립보드 | `clip.exe` 연동 (vi 모드 y로 Windows 클립보드 복사) |
| 팬 이동 | `Alt+h/j/k/l` (prefix 없이) |
| 자동 저장·복원 | tmux-resurrect + tmux-continuum 15분 간격 |
| 테마 | Catppuccin Mocha + CPU/RAM/배터리/git 상태바 |
| 파일 매니저 | `prefix + Tab` 으로 우측 50%에 Yazi |
| 설정 리로드 | `prefix + r` |

WSL2 linger도 이미 켜져 있습니다 (`Linger=yes`). 즉 PowerShell 다 닫아도 tmux 서버가 살아있습니다.

### 새 설정 적용하기

설정을 바꿨을 때:

- **현재 tmux 안에 있다면**: `prefix + r` (Ctrl+A → r) — 부분 적용 (대부분의 설정)
- **완전히 새로 시작하고 싶다면**: tmux 세션 모두 정리 후
  ```bash
  tmux kill-server   # 주의: 모든 세션 종료
  tmux new -s main   # 새로 시작
  ```
- **플러그인 신규 설치/업데이트**: tmux 안에서 `prefix + I` (대문자 I) — tpm이 플러그인 다운로드
- **`extended-keys on` 같은 일부 서버 옵션은 kill-server 후 새로 띄워야 적용됨**

---

## 2. 상황별 사용법

### 상황 A. "이제부터 작업 시작"

```bash
# PowerShell에서
wsl

# WSL 안에서
tmux new -s dev
```

`dev` 라는 이름의 세션이 열립니다. 하단에 Catppuccin 상태바가 보이면 tmux 안입니다.

### 상황 B. "잠깐 점심먹고 옴 / PC 끄지 말고 PowerShell만 닫고 싶음"

`prefix + d` (detach) → tmux에서 빠져나오기만 함, 안의 프로세스는 계속 돌아감.
이제 PowerShell 창 X로 닫아도 됩니다.

### 상황 C. "다시 들어가서 이어 작업"

```bash
# 새 PowerShell 열고
wsl
tmux ls               # 살아있는 세션 목록
tmux attach -t dev    # dev 세션에 다시 붙기
# 또는 세션이 하나면 그냥
tmux a
```

### 상황 D. "Claude Code 돌려놓고 다른 작업도 동시에"

같은 세션 안에서 **윈도우(탭) 추가**:

- `prefix + c` → 새 윈도우 생성
- `prefix + 1`, `prefix + 2` ... → 번호로 이동 (1부터 시작하도록 설정됨)
- `prefix + n` / `prefix + p` → 다음/이전 윈도우
- `prefix + ,` → 현재 윈도우 이름 바꾸기
- `prefix + w` → 윈도우 목록 (방향키로 선택)

### 상황 E. "한 화면에 Claude Code랑 로그 같이 보고 싶음"

**팬 분할**:

- `prefix + %` → 좌우로 분할
- `prefix + "` → 상하로 분할
- `Alt + h/j/k/l` → 팬 사이 이동 ⭐ **prefix 없이 바로** (이 머신에 설정됨)
- `prefix + z` → 현재 팬을 전체화면으로 줌 ⭐ 매우 자주 씀
- `prefix + x` → 현재 팬 닫기 (확인 y)
- `prefix + space` → 레이아웃 자동 정렬 (반복하면 다른 배치)
- `prefix + Ctrl+방향키` → 팬 크기 조절

### 상황 F. "여러 작업(프로젝트)을 분리해서 관리"

세션 여러 개 사용:

```bash
tmux new -s junggo      # 중고거래 프로젝트
# prefix + d 로 빠져나옴
tmux new -s homelab     # 홈랩 작업
# prefix + d
tmux ls

tmux attach -t junggo   # 원하는 거에 붙기
```

세션 사이 점프: `prefix + s` (세션 목록) → 방향키 + Enter
세션 빠른 전환: `prefix + (` / `prefix + )` (이전/다음 세션)

### 상황 G. "긴 출력 스크롤해서 위로 보고 싶음"

`prefix + [` → **복사 모드** 진입
- 방향키 / PageUp / PageDown 으로 스크롤
- `/` 검색 (vi 모드)
- `v` 선택 시작 → 방향키로 영역 → `y` 또는 `Enter` 로 **Windows 클립보드로 복사** (clip.exe 연동)
- `q` 또는 `Esc` 로 나가기

마우스 휠도 동작합니다. tmux 3.6의 `pane-scrollbars on`이 켜져 있어 팬 우측에 스크롤바도 보입니다.

### 상황 H. "복사해서 다른 데 붙여넣기"

- **마우스 드래그**: 드래그하면 자동으로 선택되고 mouse-up 시점에 Windows 클립보드로 복사됨 (`clip.exe` 연동 적용됨)
- **키보드만**: `prefix + [` → `v` 선택 시작 → 영역 지정 → `y` → Windows 어디서나 Ctrl+V

### 상황 I. "세션/윈도우/팬 정리"

```bash
# 특정 세션 종료
tmux kill-session -t homelab

# 모든 tmux 깨끗이 초기화 (주의: 다 죽음)
tmux kill-server
```

세션 안에서: `prefix + &` (윈도우 종료), `prefix + x` (팬 종료).

---

## 3. Claude Code + Codex 생산성 레시피 (2026년 5월 표준)

### 레시피 1: 프로젝트당 세션 1개 + 윈도우 4~5개 (입문자 추천)

```
세션: junggo
├─ 1:edit     (vim, neovim, 또는 그냥 ls/git)
├─ 2:claude   (claude code 돌리는 곳)
├─ 3:codex    (codex 돌리는 곳)
├─ 4:server   (django runserver, npm dev 등 장기 프로세스)
└─ 5:git      (status/diff/commit 전용)
```

세팅 흐름:

```bash
tmux new -s junggo
# 윈도우 1 생성됨 → prefix + , 로 "edit" 으로 rename
cd ~/work/junggo

# prefix + c, prefix + , → "claude"
claude

# prefix + c → "codex"
codex

# prefix + c → "server"
python manage.py runserver

# prefix + c → "git"
```

`prefix + 1~5` 로 휙휙 옮겨다닙니다.

### 레시피 2: 한 윈도우 안에서 동시 모니터링 (3-pane)

```
┌─────────────────────┬─────────────┐
│                     │             │
│   Claude Code       │  서버 로그   │
│   (큰 팬)           │  tail -f    │
│                     │             │
├─────────────────────┤             │
│   터미널/git        │             │
└─────────────────────┴─────────────┘
```

만드는 법:

1. `tmux new -s dev`
2. `prefix + %` → 좌우 분할
3. 왼쪽 팬에서 `prefix + "` → 상하 분할
4. 왼쪽 위 큰 팬에서 `claude` 실행
5. `Alt+l` 로 오른쪽 팬 이동 → `tail -f logs/dev.log`
6. `Alt+h` 로 왼쪽 → `Alt+j` 로 아래 팬 → `git status` 등
7. 답답하면 `prefix + z` 로 줌

### 레시피 3: ⭐ git worktree + claude-squad (2026 표준 멀티에이전트 워크플로우)

**현재 머신에 `cs` 명령으로 사용 가능합니다 (방금 설치됨, v1.0.17)**.

**개념**: AI 에이전트 2개 이상이 같은 디렉토리에서 일하면 충돌. 그래서 git worktree로 디렉토리를 격리하고, 각 worktree에 tmux 세션을 띄움. claude-squad가 이걸 자동화.

**기본 사용**:

```bash
# 작업할 리포에서
cd ~/work/junggo
cs                # claude-squad TUI 진입
```

claude-squad TUI 단축키:

| 키 | 동작 |
|---|---|
| `n` | 새 에이전트 세션 생성 (자동으로 worktree + tmux 세션) |
| `N` | 프롬프트와 함께 새 세션 생성 |
| `↵` / `o` | 선택한 세션에 attach해서 prompt 다시 보내기 |
| `s` | 커밋 후 브랜치를 GitHub에 push (gh CLI 사용) |
| `c` | 변경사항 checkout 후 세션 일시정지 |
| `r` | 일시정지된 세션 재개 |
| `q` | claude-squad 종료 (세션은 살아있음) |

**처음 쓸 때 필요한 설정**:

```bash
gh auth login     # claude-squad가 GitHub에 push할 때 사용
                  # 브라우저 열려서 인증, 한 번만 하면 됨
```

**Claude vs Codex 동시 비교**:

claude-squad는 에이전트 타입을 고를 수 있어서, 같은 태스크를 Claude와 Codex 각각에 시켜놓고 결과 비교하는 패턴이 가능합니다. TUI에서 `n` 누를 때 어떤 에이전트로 띄울지 선택.

### 레시피 4: Claude Code Agent Teams (Anthropic 공식, 2026-02-05 출시)

한 Claude Code 인스턴스가 "리드" 역할을 하면서 여러 "팀원 Claude"에게 일을 분배하는 기능. `~/.claude/settings.json`에 다음 추가:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

claude 안에서:

```
> "auth 모듈을 4명 팀원으로 병렬 분석해줘.
>   1명은 보안 취약점, 1명은 성능, 1명은 테스트 커버리지,
>   1명은 devil's advocate 관점으로 비판"
```

표시 모드:
- `in-process`: 한 터미널 안에서 `Shift+Down`으로 팀원 순환 (어디서나 동작)
- `split panes`: tmux split-pane으로 팀원별 팬 (**tmux 필수**)
- `auto`(기본): tmux 안이면 split, 아니면 in-process

**주의 (2026-05 known issues)**:
- experimental 단계. `/resume`이 in-process teammate를 복원하지 못함
- nested teams 불가 (팀원이 또 팀을 만들 수 없음)
- 권장 크기: 3~5명, 1명당 5~6 태스크

### 레시피 5: 장기 실행 작업을 안전하게

긴 빌드·학습·다운로드는 **tmux 안에서** 돌리세요. PowerShell 끄고 자도 살아있습니다.

```bash
tmux new -s longjob
./build_everything.sh
# prefix + d 로 detach
# 다음날 아침
tmux attach -t longjob
```

### 레시피 6: Windows Terminal 탭 + tmux 세션 매핑

Windows Terminal에서 탭을 여러 개 띄우고 각 탭에서 다른 세션에 attach.

- 탭1: `wsl` → `tmux a -t junggo`
- 탭2: `wsl` → `tmux a -t homelab`
- Windows Terminal 단축키: `Ctrl+Shift+T` (새 탭), `Ctrl+Tab` (다음 탭)

---

## 4. 단축키 표 (Prefix = Ctrl+A)

### 4.1 세션(Session)

| 단축키 | 동작 |
|---|---|
| `tmux new -s 이름` | 새 세션 생성 (셸에서) |
| `tmux ls` | 세션 목록 |
| `tmux attach -t 이름` / `tmux a` | 세션 붙기 |
| `tmux kill-session -t 이름` | 특정 세션 종료 |
| `prefix + d` | **detach** (안 죽고 빠져나오기) ⭐ |
| `prefix + s` | 세션 목록 (방향키 선택) |
| `prefix + $` | 현재 세션 이름 변경 |
| `prefix + (` / `prefix + )` | 이전/다음 세션 |

### 4.2 윈도우(Window = 탭)

| 단축키 | 동작 |
|---|---|
| `prefix + c` | 새 윈도우 생성 (현재 경로 유지) |
| `prefix + ,` | 현재 윈도우 rename |
| `prefix + n` / `prefix + p` | 다음/이전 윈도우 |
| `prefix + 1` ~ `prefix + 9` | 번호로 이동 (1부터 시작) |
| `prefix + w` | 윈도우 목록 |
| `prefix + L` | 마지막 사용 윈도우 (이 머신 단축) |
| `prefix + &` | 현재 윈도우 종료 (확인 y) |
| `prefix + f` | 윈도우 텍스트 검색 |

### 4.3 팬(Pane = 분할)

| 단축키 | 동작 |
|---|---|
| `prefix + %` | 세로(좌우) 분할 (현재 경로 유지) |
| `prefix + "` | 가로(상하) 분할 (현재 경로 유지) |
| **`Alt + h/j/k/l`** | **팬 이동 (prefix 없이)** ⭐ 이 머신 단축 |
| `prefix + 방향키` | 팬 이동 (기본) |
| `prefix + o` | 다음 팬으로 순환 |
| `prefix + z` | **현재 팬 줌 토글** ⭐ |
| `prefix + x` | 현재 팬 종료 |
| `prefix + space` | 레이아웃 변경 |
| `prefix + {` / `prefix + }` | 팬 위치 교체 |
| `prefix + Ctrl+방향키` | 팬 크기 조절 |
| `prefix + !` | 현재 팬을 별도 윈도우로 분리 |
| `prefix + q` | 팬 번호 잠깐 표시 |
| `prefix + Tab` | 우측 50%에 Yazi (파일 매니저) ⭐ 이 머신 단축 |

### 4.4 복사·스크롤 모드 (vi 모드)

| 단축키 | 동작 |
|---|---|
| `prefix + [` | 복사 모드 진입 |
| 방향키/PgUp/PgDn | 스크롤 |
| `/` 또는 `?` | 앞/뒤 검색 |
| `v` | 선택 시작 |
| `y` 또는 `Enter` | **Windows 클립보드로 복사** ⭐ |
| 마우스 드래그 | 자동 선택 → 클립보드 |
| `q` 또는 `Esc` | 복사 모드 종료 |
| `prefix + ]` | tmux 버퍼 붙여넣기 |

### 4.5 Claude Code 안에서 자주 쓰는 키 (충돌 회피용 우회 포함)

| 단축키 | 동작 |
|---|---|
| `Shift + Enter` | Claude Code 줄바꿈 (extended-keys 적용 후 동작) |
| `Ctrl + J` | Claude Code 줄바꿈 (어디서나 동작하는 fallback) |
| `Ctrl + O` | Claude Code 상세 펼치기 (tmux와 안 겹침) |
| `Ctrl + T` | Claude Code 태스크 리스트 토글 |
| `prefix + o` | (이 머신 추가) Claude Code의 Ctrl+O 강제 전달 — 일부 터미널에서 중복 키 발생 시 |
| `prefix + t` | (이 머신 추가) Claude Code의 Ctrl+T 강제 전달 |

### 4.6 기타

| 단축키 | 동작 |
|---|---|
| `prefix + ?` | 단축키 도움말 (q로 종료) |
| `prefix + :` | tmux 명령 프롬프트 |
| `prefix + r` | ~/.tmux.conf 재로드 ⭐ 이 머신 단축 |
| `prefix + I` | (대문자) tpm 플러그인 설치/업데이트 |
| `prefix + t` | (기본) 큰 시계 — 이 머신은 Claude Code Ctrl+T로 재할당됨 |

---

## 5. 자주 쓰는 명령어 (셸에서)

```bash
# --- tmux 기본 ---
tmux ls                              # 세션 목록
tmux new -s 이름                      # 새 세션
tmux attach -t 이름                   # 붙기
tmux a                               # 세션 하나면 그냥
tmux kill-session -t 이름             # 특정 세션 종료
tmux kill-server                     # 전부 종료 (주의)
tmux rename-session -t 옛 새         # 세션 이름 변경
tmux source-file ~/.tmux.conf        # 설정 재로드

# --- claude-squad (멀티 에이전트) ---
cs                                   # TUI 진입
cs --help                            # 도움말

# --- git worktree (수동) ---
git worktree add ../proj-feature feature-branch
git worktree list
git worktree remove ../proj-feature
```

---

## 6. 트러블슈팅

### "no server running"
- `loginctl show-user bolt1 | grep Linger` → `yes` 확인 (이미 적용됨)
- 그래도 죽는다면 systemd user 로그 확인: `journalctl --user -n 50`

### Prefix가 안 먹어요
- 보조 Prefix `Ctrl+B`도 살아있으니 시도해보세요
- Claude Code 안에서 `Ctrl+B`는 가로채지므로 **반드시 `Ctrl+A` 사용**
- 한영 키 상태 확인 (한글 입력 모드면 키 안 감)

### Claude Code에서 Shift+Enter가 줄바꿈 안 됨
- `extended-keys on` + `xterm*:extkeys` 적용 후 **tmux 서버 재시작 필요**:
  ```bash
  tmux kill-server
  tmux new -s main
  ```
- 그래도 안 되면 `Ctrl+J`를 fallback으로 사용

### Claude Code 화면이 깜빡임 (flicker)
- `xterm*:sync` 설정이 들어가 있어야 함 (현재 적용됨)
- 그래도 발생하면 환경변수로:
  ```json
  // ~/.claude/settings.json
  { "env": { "CLAUDE_CODE_NO_FLICKER": "1" } }
  ```

### Claude Code 색상이 칙칙함 (banded gradient)
- 이건 알려진 이슈 (anthropics/claude-code#59867, 2026 신규)
- 클라이언트 측 완전 해결책 없음 — Anthropic 수정 대기
- 부분 완화: `set -as terminal-features ',tmux-256color:RGB'` (이미 유사 적용)

### claude-squad에서 push가 안 됨
- `gh auth login` 안 했을 수 있음. 한 번 실행:
  ```bash
  gh auth login
  # GitHub.com → HTTPS → 브라우저 인증
  ```

### 마우스 스크롤이 이상해요
- tmux 3.6의 `pane-scrollbars on`이 켜져 있어 우측에 스크롤바가 표시됨
- 휠 스크롤이 어플리케이션(htop 등)으로 전달되지 않으면 `set -g mouse off` 잠시 끄거나 해당 앱의 마우스 모드 확인

### Yazi가 prefix + Tab으로 안 열림
- Yazi 설치 확인: `which yazi`
- 없으면: `cargo install --locked yazi-fm yazi-cli` 또는 GitHub에서 바이너리

### "갑자기 tmux가 멈춘 것 같아요"
- `prefix + z` 가 켜져서 한 팬만 보이는 상태일 수 있음 → 다시 `prefix + z`
- `Ctrl+S` 로 출력 멈춘 상태 → `Ctrl+Q` 로 해제

### 환경변수가 tmux 안에서 안 보임
```bash
# 새 환경변수가 tmux 세션에 안 전파될 때
tmux set-environment -g API_KEY "value"
# 또는 새 셸 띄울 때
tmux source-file ~/.tmux.conf
```

---

## 7. anti-patterns (2026년 기준 "이러지 마세요")

1. **tmux 기본 Prefix(Ctrl+B) 그대로 두기** → Claude Code가 가로채서 tmux 거의 못 씀
2. **iTerm2의 `tmux -CC` (control mode)** → Claude Code의 alt-screen/마우스 깨짐 (일반 tmux 사용)
3. **한 윈도우에 5개 이상 split** → pane이 작아지면 Claude Code TUI 깨짐, 윈도우 단위로 나눌 것
4. **에이전트 2개 이상이 같은 worktree 공유** → 충돌. 1 에이전트 = 1 worktree
5. **`/bg`(Agent View)만 믿고 tmux 없이 노트북 닫기** → Claude Code 프로세스 죽으면 background도 죽음. **외곽은 항상 tmux**
6. **vague prompt로 Agent Teams teammate spawn**: "auth 보안 확인해줘" → "src/auth/의 JWT 토큰 핸들링, 세션 만료 처리, CSRF 방어 3가지 관점에서 OWASP Top 10 매핑해서 보고" 식으로 구체화
7. **`tmux capture-pane`을 AI에 그대로 파이프** → ANSI escape 포함되어 컨텍스트 오염
8. **history-limit 기본값(2000)** → AI 출력은 길어서 부족 (현재 100000으로 적용됨)
9. **`--dangerously-skip-permissions`를 lead에서 켜고 잊기** → 모든 teammate가 상속, 위험

---

## 8. 30초 치트시트

```
Prefix = Ctrl+A   (먼저 누르고 떼고 → 다음 키)

세션:   d=빠져나옴   s=목록   $=rename
윈도우: c=새창   1~9=이동   n/p=다음/이전   ,=rename   L=마지막창
팬:    %=좌우   "=상하   z=줌   x=닫기   Tab=Yazi   r=설정리로드
       Alt+hjkl=팬이동(prefix 없이)
스크롤: [=진입   v=선택시작   y=Win 클립보드 복사   q=나감
도움말: ?         명령: :

셸:    tmux ls / tmux a / tmux new -s 이름 / tmux kill-session -t 이름
       cs           (claude-squad TUI - 멀티 에이전트)
```

---

## 9. 점진적 학습 로드맵

**Day 1 (오늘)**
- `tmux new -s main` 으로 시작, `prefix + d` 로 detach, `tmux a` 로 재진입 3회 반복
- `prefix + c` 로 윈도우 2~3개 만들어보기, `prefix + 1/2/3` 으로 이동
- `prefix + %` 로 좌우 분할 한 번 해보기

**Week 1**
- `Alt+hjkl` 팬 이동을 prefix 키 없이 자연스럽게
- `prefix + z` 줌 토글 익숙해지기
- 실제 Claude Code/Codex를 윈도우 분리해서 띄워보기
- 한 프로젝트 = 한 세션 패턴 정착

**Week 2~3**
- 복사 모드 (`prefix + [` → `v` → `y`) 키보드만으로 익숙해지기
- Catppuccin 상태바 정보 (브랜치, CPU, 시간) 활용
- `cs` (claude-squad) TUI 한 번 띄워서 멀티 에이전트 워크플로우 체험
- `gh auth login` 한 번 해두기

**Month 2~**
- git worktree 직접 만들고 윈도우 단위로 에이전트 띄우는 패턴
- Claude Code Agent Teams 실험 (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- 자기 워크플로우에 맞게 `~/.tmux.conf` 커스터마이즈

---

## 10. 처음 0부터: Windows 켜고 tmux 안까지

### 10.1 단축으로 들어가기 — Windows Terminal 프로필 셋업 (한 번만)

매번 `wsl` 치고 `tmux a` 치는 게 귀찮다면, Windows Terminal에 "탭 열면 바로 tmux 안" 프로필을 만들어두면 됩니다.

> **이 머신엔 이미 자동 적용됨** (`{7f5a3c8e-c7a5-4d2e-8a3b-2c9f1e0d7a4b}` GUID로 "Claude (tmux)" 프로필 추가, 기본 프로필 변경, Ctrl+Shift+1/2 단축키 추가).
> 백업: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json.bak.20260522-pre-claude-profile`

**다른 컴퓨터에서 동일 셋업하는 방법** (이 매뉴얼을 다른 컴퓨터에서 볼 때 그대로 따라가기):

#### A. settings.json 위치 찾기
```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```
(Microsoft Store가 아닌 Preview 버전이면 `Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe`)

Windows Terminal 설정 UI 우상단의 "JSON 파일 열기" 또는 `Ctrl + Shift + ,` 로도 열림.

#### B. profiles.list 에 새 프로필 추가
다른 프로필 객체 옆에 `,` 와 함께 추가:

```json
{
    "guid": "{7f5a3c8e-c7a5-4d2e-8a3b-2c9f1e0d7a4b}",
    "hidden": false,
    "name": "Claude (tmux)",
    "commandline": "wsl.exe -d Ubuntu -- bash -lc \"tmux new -As main\"",
    "tabTitle": "Claude",
    "colorScheme": "Campbell",
    "font": { "face": "Cascadia Mono" }
}
```

> GUID는 프로필 식별자. 같은 머신에서 충돌만 안 나면 OK. 다른 머신에선 위 값 그대로 써도 되고, PowerShell `[guid]::NewGuid()` 로 새로 만들어도 됨.

#### C. 기본 프로필 변경
파일 상단의 `"defaultProfile"` 값을 새 프로필 GUID로:
```json
"defaultProfile": "{7f5a3c8e-c7a5-4d2e-8a3b-2c9f1e0d7a4b}",
```

#### D. 단축키 추가 (선택 — 강력 추천)
`keybindings` 배열에 추가:
```json
{
    "command": { "action": "newTab", "profile": "Claude (tmux)" },
    "keys": "ctrl+shift+1"
},
{
    "command": { "action": "newTab", "profile": "Windows PowerShell" },
    "keys": "ctrl+shift+2"
}
```

#### E. 저장 → Windows Terminal 자동 reload

설정파일을 저장하면 Windows Terminal이 자동으로 새 설정 적용. 안 되면 한 번 닫았다 다시 열기.

### 10.2 매일 쓰는 가장 짧은 길 (셋업 후)

이제 매일은 단 두 단계:

| 행동 | 결과 |
|---|---|
| **`Win + 1`** (작업 표시줄에 Terminal 고정한 경우) 또는 작업 표시줄의 Terminal 아이콘 클릭 | Windows Terminal 새 창 → 기본 프로필 "Claude (tmux)" → WSL Ubuntu → tmux main 세션 자동 attach |
| 이미 Terminal이 열려있고 새 탭을 원하면 **`Ctrl + Shift + 1`** | 같은 창에 새 Claude 탭 |
| 그냥 PowerShell 탭이 필요하면 **`Ctrl + Shift + 2`** | PowerShell 새 탭 |

**즉 평균 키 입력 = 0회** (작업 표시줄 클릭 한 번 또는 Win+1 두 키).

### 10.3 매일 쓰는 가장 짧은 길 — 셋업 안 한 경우

1. **Windows 잠금 해제**
2. **Windows Terminal 열기** — 다음 중 편한 거 아무거나:
   - 작업 표시줄의 Terminal 아이콘 클릭
   - 시작 메뉴 → "Terminal" 검색 → Enter
   - `Win + R` → `wt` 입력 → Enter
   - `Win + X` → "터미널" 선택
3. 기본으로 PowerShell 탭이 열림. 입력:
   ```
   wsl
   ```
4. WSL Ubuntu 셸로 진입 (`bolt1@DESKTOP-FNG6A7O:/mnt/c/Users/bolt1$`).
5. tmux 들어가기:
   ```bash
   tmux a              # 기존 세션에 붙기
   ```
   - 세션이 없으면 `no sessions` 에러 → 그때만 `tmux new -s main`
   - 둘을 한 줄로: `tmux new -As main` (있으면 attach, 없으면 만들고 attach)

매일 쓰면 손에 익습니다. **3초 안에 tmux 안**.

### 10.4 시작 메뉴/단축키로 더 줄이기

§10.1의 GUI 셋업이 끝났다는 전제로:

- Windows Terminal을 **작업 표시줄에 고정** → `Win + 1` (또는 2/3...) 한 번에 열림
- 부팅 직후 자동 시작: `시작프로그램` 폴더 (`Win+R` → `shell:startup`)에 Windows Terminal 바로가기 넣기
- 같은 창에서 새 Claude 탭: **`Ctrl + Shift + 1`** (§10.1에서 이미 설정됨)
- 같은 창에서 PowerShell 탭: **`Ctrl + Shift + 2`**

### 10.5 새 세션 / 기존 세션 빨리 구분하기

```bash
tmux ls
# main: 3 windows (created Thu May 22 ...) (attached)
# longjob: 1 windows
```

- 세션이 **하나면** → `tmux a` (그냥 붙음)
- 여러 개면 → `tmux a -t main`
- 둘 다 어차피 살아 있는 거면 `tmux new -As main` 한 줄로 안전 (있으면 attach, 없으면 새로)

### 10.6 끝낼 때 (퇴근/취침)

PowerShell 창을 **그냥 X로 닫아도 됩니다**. linger 켜져 있으니 tmux와 안의 Claude Code/Codex/서버 모두 살아 있음. 다음에 들어오면 그대로.

---

## 11. 다른 컴퓨터에서 이 머신으로 접속해 이어 작업하기

> 가정: 두 머신 모두 같은 **Tailscale** 네트워크에 들어 있음 (이 머신엔 이미 Tailscale 설치됨). LAN만 쓴다면 IP/호스트명만 바꿔서 그대로 적용 가능.

### 11.1 한 번만 하는 셋업 (이 머신에)

**A. Windows OpenSSH 서버 켜기** — 한 번:

1. 시작 메뉴 → "선택적 기능 추가" 검색 → 열기
2. "기능 보기" → 검색창에 `OpenSSH` → **"OpenSSH Server"** 체크 → 설치
3. 시작 메뉴 → "서비스" 검색 → 열기
4. 목록에서 **"OpenSSH SSH Server"** 찾기 → 우클릭 → "속성"
5. **시작 유형: 자동** → "시작" 버튼 → 확인
6. 방화벽은 OpenSSH 설치 시 자동으로 22번 포트 허용됨

빠른 확인 (PowerShell 관리자):
```powershell
Get-Service sshd                 # Status: Running 이어야 함
Get-NetFirewallRule -Name *OpenSSH* | Select Name, Enabled
```

**B. SSH 공개키 등록** (비밀번호 안 쓰고 안전하게):

(다른 컴퓨터, 즉 클라이언트에서)
```bash
# 키가 없으면 만들기 (한 번만)
ssh-keygen -t ed25519 -C "my-laptop"
# Enter 3번 (기본 경로, 비밀번호 없이 or 있게)

# 공개키 내용 보기
cat ~/.ssh/id_ed25519.pub
# ssh-ed25519 AAAA... my-laptop  ← 이 한 줄을 복사
```

(이 머신, 즉 서버에서) — PowerShell 관리자로:

> Windows의 일반 사용자(`bolt1`)면 `C:\Users\bolt1\.ssh\authorized_keys`.
> 관리자 계정이면 `C:\ProgramData\ssh\administrators_authorized_keys` (Windows OpenSSH 특수 규칙).

대부분 일반 사용자 케이스:
```powershell
mkdir C:\Users\bolt1\.ssh -Force
notepad C:\Users\bolt1\.ssh\authorized_keys
# 메모장에 위에서 복사한 공개키 한 줄 붙여넣고 저장
```

권한이 맞아야 동작:
```powershell
icacls C:\Users\bolt1\.ssh\authorized_keys /inheritance:r /grant "bolt1:F" /grant "SYSTEM:F"
```

**C. 이 머신의 Tailscale 호스트명 확인** (PowerShell):
```powershell
tailscale status
# 본인 줄에 보이는 이름 (예: desktop-fng6a7o) ← 이게 다른 곳에서 접속할 때 호스트명
```

### 11.2 매일 쓰는 루틴 (다른 컴퓨터에서)

다른 컴퓨터에 **Tailscale 켜져 있어야** 함 (어디서나 동작 — 집/카페/회사/해외).

기본 접속:
```bash
ssh bolt1@desktop-fng6a7o
# Windows의 PowerShell이 떨어짐 (Windows OpenSSH가 받았기 때문)
wsl                  # WSL Ubuntu로
tmux a               # tmux 세션 attach
```

한 줄로 자동 진입:
```bash
ssh -t bolt1@desktop-fng6a7o "wsl tmux new -As main"
```
- `-t` 는 **TTY 강제** — tmux 같은 인터랙티브 도구는 이거 없으면 화면 깨짐
- `new -As main` — main이 있으면 attach, 없으면 생성 후 attach

### 11.3 더 편하게 — SSH config 알리아스

다른 컴퓨터의 `~/.ssh/config` (없으면 만들기):
```
Host desk
  HostName desktop-fng6a7o
  User bolt1
  RequestTTY yes
  RemoteCommand wsl tmux new -As main
  ServerAliveInterval 30
  ServerAliveCountMax 6
```

이제 그 컴퓨터에서:
```bash
ssh desk
```
한 줄로 곧장 **이 머신의 main tmux 세션 안**.

`ServerAliveInterval`은 30초마다 keepalive 보내 연결 유지 (Wi-Fi 흔들림 대응).

### 11.4 흔한 함정과 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| `Connection refused` | OpenSSH 서버 안 켜져있음 | §11.1-A 다시 |
| `Permission denied (publickey)` | 키가 안 맞거나 권한 문제 | `icacls` 명령 다시 / `~/.ssh/authorized_keys` 한 줄 확인 |
| 접속 후 한글 깨짐 | 인코딩 | PowerShell 단에서 `chcp 65001` 또는 클라이언트 폰트를 NF로 |
| 접속은 되는데 tmux 안에 색이 이상 | TERM 변수 | ssh config에 `SendEnv TERM` + 클라이언트에서 `TERM=xterm-256color` |
| Tailscale 이름으로 접속 안 됨 | MagicDNS 꺼짐 | https://login.tailscale.com/admin/dns → MagicDNS 켜기 |
| 가끔 끊김 | NAT 타임아웃 | `ServerAliveInterval 30` 추가 (§11.3) |

---

## 12. 모바일에서 접속해 이어 작업하기

> tmux의 진가가 가장 빛나는 시나리오. 데스크탑 작업을 그대로 폰에서 이어보고, 출근길 지하철에서도 빌드 로그 모니터링 가능.

### 12.1 추천 앱

| 플랫폼 | 1순위 추천 | 무료 대안 |
|---|---|---|
| **iOS** | **Blink Shell** (유료 ~$20, **Mosh 지원**, 키보드 최적화) | a-Shell, Termius |
| **Android** | **Termius** (무료, 안정적, 동기화) | Termux (오픈소스, 고급), JuiceSSH |

Mosh 지원 여부가 모바일에서 결정적입니다 (이유는 §12.4).

### 12.2 한 번만 하는 셋업 (모바일 쪽)

**1. Tailscale 모바일 앱 설치 + 로그인**
- 데스크탑과 같은 계정으로 로그인
- 백그라운드 실행 권한 허용 (배터리 최적화 예외 추가하면 연결 안정)

**2. SSH 키 생성 또는 import**

Blink Shell 예시:
- 앱 안에서 `config` → `Keys` → `+` → ED25519 → 이름 (예: `iphone`)
- 생성된 공개키를 복사 (Share 버튼)

Termius 예시:
- Keys → New Key → ED25519 → 저장 → 공개키 복사

복사한 공개키 한 줄을 데스크탑의 `C:\Users\bolt1\.ssh\authorized_keys`에 **추가** (§11.1-B 와 같은 방식).

**3. 호스트 등록 (모바일 앱)**
- Host: `desktop-fng6a7o` (Tailscale MagicDNS 이름)
- Port: `22`
- User: `bolt1`
- Key: 방금 만든 키 선택

### 12.3 매일 쓰는 루틴 (모바일)

1. **Tailscale 앱이 켜져 있는지 확인** (잠금 화면 위젯 추천)
2. SSH 앱 → 호스트 → 연결
3. PowerShell 떨어지면 `wsl` → `tmux a`

**자동 attach — 호스트의 "명령" 필드에**:
- Blink Shell: 호스트 설정에 `startup command` → `wsl tmux new -As main`
- Termius: Host → Advanced → SSH → Startup Snippet → `wsl tmux new -As main`

이러면 호스트 누르자마자 곧장 tmux 안.

### 12.4 Mosh 강력 권장 (모바일 핵심)

**문제**: 일반 SSH는 TCP라서 네트워크가 흔들리면 (5G ↔ Wi-Fi 전환, 지하철 진입, 화면 잠금) 세션이 끊김. tmux 자체는 살아있지만 SSH 재연결하고 attach 다시 해야.

**해결**: Mosh는 UDP 기반에 roaming 지원. **네트워크 끊겨도 연결 유지, IP 바뀌어도 그대로**. 화면 변경분만 전송해서 모바일에 최적.

**Mosh 셋업** — 이 머신 WSL 안에 한 번:
```bash
sudo apt install -y mosh
```

Windows 방화벽에 Mosh UDP 포트(60000~61000) 열기 (PowerShell 관리자):
```powershell
New-NetFirewallRule -Name "Mosh" -DisplayName "Mosh" -Protocol UDP -LocalPort 60000-61000 -Action Allow
```

**모바일 앱에서**:
- Blink Shell: 호스트 설정에 `Mosh: ON`
- 명령은 동일하게 `wsl tmux new -As main`

다만 Windows OpenSSH 서버를 거치는 구조라 Mosh는 WSL sshd로 직접 가는 게 깔끔. 더 깊은 셋업이 필요하면 별도 가이드 요청 주세요 (§12.6 참조).

### 12.5 모바일 입력 팁

| 팁 | 설명 |
|---|---|
| **Ctrl+A 매핑** | tmux prefix 자주 누르니 single tap으로 매핑 (Blink: `SmartKeys`, Termius: Modifier Buttons) |
| **Esc/Ctrl/Alt 행** | 화면 상단/하단에 항상 표시되는 키바 enable |
| **한영 입력** | tmux 안 한글 입력은 종종 깨짐. 짧은 명령만 키보드, 긴 문장은 클립보드 paste 권장 |
| **세로 모드 vs 가로 모드** | tmux는 좁은 화면도 OK지만 Claude Code TUI는 가로 모드 권장 (80 column 이상) |
| **터치 스크롤** | 대부분 앱이 두 손가락 스와이프로 tmux 스크롤 (mouse on 설정 덕분에) |

### 12.6 모바일에서 자주 쓰는 명령 ("앱 등록 명령" 자리에 넣어두면 편함)

| 목적 | 명령 |
|---|---|
| main 세션 attach (없으면 생성) | `wsl tmux new -As main` |
| Claude Code 작업 세션 직행 | `wsl tmux new -As claude-work \; send-keys "cd ~/work/junggo && claude" Enter` |
| 빌드 모니터링 세션 | `wsl tmux new -As longjob` |
| claude-squad TUI | `wsl bash -lc "cd ~/work/junggo && cs"` |

### 12.7 보안 한 줄

- **Tailscale 위에서만 노출** — 일반 인터넷에 22번 포트 열지 마세요
- 모바일 앱 자체에 잠금 (Face ID / 지문)
- SSH 키에 passphrase 추가 권장 (앱이 키체인에 저장해줘서 매번 안 물음)

---

## 부록 A. 현재 적용된 핵심 설정 한눈에

```tmux
# Prefix
unbind C-b
set -g prefix C-a
set -g prefix2 C-b
bind C-a send-prefix

# Claude Code 필수
set -g allow-passthrough on
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'
set -as terminal-features ',xterm*:sync'

# 편의
set -g history-limit 100000
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -sg escape-time 10
set -g pane-scrollbars on        # tmux 3.6 신기능

# 팬 이동 prefix 없이
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

# Windows 클립보드 연동
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'clip.exe'

# 자동 저장/복원
set -g @continuum-restore 'on'
```

전체 파일: `~/.tmux.conf`
백업: `~/.tmux.conf.bak.*` (변경 이전 버전 보관)

---

## 부록 B. 자주 묻는 질문

**Q. Agent View(`/bg`)와 tmux 중 뭘 써야 하나요?**

A. 둘 다 씁니다. tmux는 외곽(OS 레벨 영속성), Agent View는 안쪽(Claude Code 안에서 백그라운드 작업 관리). Claude Code 프로세스가 죽으면 Agent View도 같이 죽기 때문에 SSH 끊김·노트북 닫기·재부팅 시나리오는 여전히 tmux가 필요합니다.

**Q. claude-squad와 Agent Teams 중 뭘 써야 하나요?**

A. 두 도구의 목적이 다릅니다.
- **claude-squad (cs)**: 여러 AI 에이전트(Claude, Codex, Gemini 등)를 **다른 brand** 섞어서 병렬로 돌릴 때. git worktree 자동 관리.
- **Agent Teams**: 한 Claude가 다른 Claude들을 **하나의 brand 안에서 위임 구조**로 운영. lead-teammate 위계.

같이 써도 됩니다. cs로 worktree별 Claude 띄우고, 각 Claude 안에서 Agent Teams로 또 분할.

**Q. Codex CLI에 worktree 통합이 없다는데?**

A. 2026-02 현재 OpenAI Codex CLI는 자체 worktree 플래그가 없음 (issue #12862 오픈). 그래서 사람들이 claude-squad나 OMX(Oh My Codex) 같은 외부 도구로 감쌈. Codex는 자체적으로 native worktree 지원과 skills/automations는 추가했지만 tmux 통합은 아직.

**Q. 세션 백업이 어디 저장되나요?**

A. `~/.tmux/resurrect/last`. 15분마다 continuum이 자동 저장. 재부팅 후 tmux 처음 띄울 때 자동 복원됨.

**Q. 다른 사람들도 이런 어려움 겪나요?**

A. 매우 흔합니다. 2026년 초까지도 Claude Code + tmux 조합은 known issue가 여러 건 (#26629 Shift+Enter, #35936 Ctrl+B 가로채기, #37283 flicker, #59867 컬러 다운샘플링, #14635 WSL 클립보드). Anthropic 공식 문서가 "tmux 사용 시 이런 설정을 추가하세요"라고 명시할 정도. 이 매뉴얼은 그 known issue들을 모두 우회·해결한 설정 기준입니다.
