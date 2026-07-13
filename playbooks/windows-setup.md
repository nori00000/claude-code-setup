# Claude Code on Windows — 셋업 플레이북 v1.0

> **작성자**: alive (Urban Jungle CEO, Connection Designer)
> **첫 셋업 일자**: 2026-05-20 (Windows + PowerShell + Claude Max + Opus 4.7)
> **목적**: 다음 Windows 컴퓨터(또는 누구든)에서 30분 안에 동일 환경 재현
> **사용법**: 사람이 읽고 단계 진행 + 다음 컴퓨터의 Claude Code에게 `prompts/master-setup-prompt.md`를 그대로 던지기

---

## 📋 목차

0. [메타정보](#0-메타정보)
1. [목표](#1-목표-why)
2. [핵심 개념: 설정 5계층](#2-핵심-개념-설정-5계층)
3. [문제 접근 방식](#3-문제-접근-방식-methodology)
4. [근본 원인 분석 — 7가지 함정](#4-근본-원인-분석--7가지-함정)
5. [해결 방안 — Phase별 실행 절차](#5-해결-방안--phase별-실행-절차)
6. [AI용 마스터 프롬프트](#6-ai용-마스터-프롬프트)
7. [장애 요인 및 트러블슈팅](#7-장애-요인-및-트러블슈팅)
8. [검증 체크리스트](#8-검증-체크리스트)
9. [확장 경로 (What If)](#9-확장-경로-what-if)
10. [부록 — 레퍼런스](#10-부록--레퍼런스)

---

## 0. 메타정보

| 항목 | 값 |
|---|---|
| 적용 OS | Windows 10/11 (macOS/Linux는 일부 명령 다름, 별도 표시) |
| 셸 | PowerShell (시스템) + git-bash (Claude Code 내장) |
| 플랜 | Claude Max (Team/Enterprise도 호환, Pro는 auto 모드 불가) |
| Claude Code 버전 기준 | 2.1.145 (최소 2.1.111+) |
| 모델 | Opus 4.7 (Max 플랜에서 auto 모드 작동 조건) |
| 핵심 플러그인 | omc (oh-my-claudecode, Yeachan-Heo) |
| 예상 소요 시간 | 30분 (백업 5분 + 적용 10분 + 검증 15분) |

> 머신 ID는 `FLEET.md`의 명명 규칙(`{os}-{cpu}-{gpu|form}`)을 따른다. 예: `win-i9-4070`.

---

## 1. 목표 (Why)

### 1.1 한 줄 정의

**"마찰 없는 자동화 환경"** — 도구가 사용자의 흐름(병렬 워크스트림, 20분 액션 단위)에 맞춰 작동하되, 위험한 명령은 자동으로 차단되는 3계층 안전 구조.

### 1.2 달성하려는 3가지 상태

| 레이어 | 작동 방식 | 결과 |
|---|---|---|
| **Auto Mode (classifier)** | AI가 명령마다 안전성 판단 → 안전하면 자동 실행 | 권한 묻는 프롬프트 90% 사라짐 |
| **Deny 안전벨트** | 위험 명령 6개는 어떤 모드에서도 영구 차단 | 실수로 시스템 망가뜨릴 가능성 차단 |
| **Allow 화이트리스트** | 자주 쓰는 안전 명령은 명시적 통과 | classifier 부담 감소, 속도 향상 |

> Mac 트랙은 여기에 **Python PreToolUse hook**(`hooks/deny-destructive-commands.py`)이 추가로 깔리는 4계층 구조. Windows에서도 hook 포팅은 가능하나 v1.0에서는 deny 화이트리스트로 충분.

### 1.3 측정 가능한 성공 기준

- [ ] `/status`에서 `Default permission mode: Auto mode` 표시
- [ ] 일반 파일 생성/편집 시 권한 프롬프트 안 뜸
- [ ] `rm -rf`, `sudo`, `git push --force` 명령은 차단됨
- [ ] PostToolUse hook 에러 메시지 없음
- [ ] omc 플러그인의 MCP 서버 (sequential-thinking, context7) ✔
- [ ] `claude --version` 자동 업데이트 채널이 `latest`

---

## 2. 핵심 개념: 설정 5계층

Claude Code의 설정은 **5개 레이어**에서 옵니다. 위로 갈수록 우선순위가 높습니다.

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Enterprise managed settings                              │  ← 강제
│    C:\ProgramData\ClaudeCode\managed-settings.json          │     (개인 PC엔 없음)
├─────────────────────────────────────────────────────────────┤
│ 2. Project local settings                                   │  ← 프로젝트 폴더별
│    .claude/settings.local.json (git ignored)                │     개인 설정
├─────────────────────────────────────────────────────────────┤
│ 3. Project shared settings                                  │  ← 프로젝트 폴더별
│    .claude/settings.json (git에 commit)                     │     팀 공유
├─────────────────────────────────────────────────────────────┤
│ 4. User settings                                            │  ← 사용자 전역
│    ~/.claude/settings.json                                  │     (이 가이드 메인 타겟)
├─────────────────────────────────────────────────────────────┤
│ 5. User config (별도 파일!)                                 │  ← AutoUpdates 등
│    ~/.claude.json (점 두 개 아님, 점 1개)                   │     모델 선호도
└─────────────────────────────────────────────────────────────┘
```

### 🚨 핵심 함정: 두 파일을 헷갈리지 말기

| 파일 | 무엇 | 예시 키 |
|---|---|---|
| `~/.claude/settings.json` | 권한, hooks, 마켓플레이스 | `permissions`, `hooks`, `extraKnownMarketplaces` |
| `~/.claude.json` | 사용자 환경설정 | `autoUpdates`, `numStartups`, `installMethod` |

오늘의 미스터리 "autoUpdatesChannel: latest로 박아도 disabled로 표시" 의 정체:
**`autoUpdates: false`가 `~/.claude.json`에 박혀 있어서 settings.json의 채널 설정을 override**.

---

## 3. 문제 접근 방식 (Methodology)

### 3.1 5단계 진단-적용 흐름

```
[1] 진단    → 현재 상태 파악 (어떤 파일이 있는지, 어떤 값인지)
[2] 백업    → 모든 변경 전 타임스탬프 백업
[3] 적용    → 한 파일씩 변경 (settings.json → settings.local.json → .claude.json)
[4] 검증    → 슬래시 명령으로 변경 반영 확인
[5] 테스트  → 실제 명령 실행해서 auto/deny 작동 확인
```

### 3.2 디버깅 사고법

문제가 생기면 **"어느 계층의 설정이 이기는가?"**를 먼저 묻기:

```
증상: "settings.json에 X를 넣었는데 작동 안 함"
  ↓
질문 1: settings.local.json에 X와 충돌하는 값이 있나? (override 1순위)
질문 2: ~/.claude.json에 별도 키로 X 관련 설정이 있나? (별도 파일 1순위)
질문 3: Enterprise managed-settings가 있나? (있으면 모든 것 override)
질문 4: 환경변수가 있나? (CLAUDE_CODE_*, DISABLE_AUTOUPDATER 등)
```

### 3.3 안전성 원칙

1. **백업은 무조건, 타임스탬프 붙여서**: `settings.json.bak.20260520-143954`
2. **JSON 유효성 즉시 검증**: `ConvertFrom-Json` 또는 `Get-Content | ConvertFrom-Json`
3. **롤백 명령 미리 준비**: 한 줄로 복원 가능하게
4. **재시작 후 검증**: 모든 설정 변경은 **새 세션부터 반영**

---

## 4. 근본 원인 분석 — 7가지 함정

오늘 실제로 부딪힌 함정들. 다음 셋업에서 이걸 피하면 시간을 1시간 이상 절약합니다.

### 함정 #1: `Stop` hook + `matcher` 조합

**증상**: hook이 의도대로 작동 안 함

**원인**: `Stop` 이벤트는 Claude의 응답 종료 시 발동되는 단일 이벤트라서 `matcher`가 무의미. matcher는 `PreToolUse`/`PostToolUse` 같은 도구 이벤트에서만 작동.

**해결**: 파일 편집 후 자동 동작 원하면 `PostToolUse`, 위험 차단 원하면 `PreToolUse`.

**보너스**: Stop hook에서 파일 쓰거나 명령 실행하면 **무한 루프** 위험. Stop hook은 로그/알림 같은 수동적 작업만.

### 함정 #2: PowerShell 변수 확장 in single quote

**증상**: hook에서 `$env:USERPROFILE`이 리터럴로 들어가 경로 깨짐

**원인**: PowerShell single quote `'...'`는 변수 확장 안 함. Double quote `"..."`만 확장.

**예시**:
```powershell
# ❌ 안 됨 (literal)
'$env:USERPROFILE/.claude/hooks/auto-commit.ps1'

# ✅ 됨 (확장)
"$env:USERPROFILE/.claude/hooks/auto-commit.ps1"
```

**JSON 안에서 PowerShell 명령 짤 때**: JSON 이스케이핑 + PowerShell 따옴표 규칙이 겹쳐서 더 복잡해짐. **외부 스크립트 파일**로 빼고 hook에서는 그 스크립트만 호출하는 게 안전.

### 함정 #3: `settings.local.json` 누적 비대화

**증상**: 권한 프롬프트에서 "Always allow" 누를 때마다 이 파일이 커짐 → 한 달이면 10kB+

**원인**: Claude Code가 사용자의 일회성 승인을 영구 allow로 기록.

**위험**:
- 너무 구체적인 명령들이 박혀서 미관 손상
- 보안적으로 위험한 명령(`unset CLAUDECODE && claude -p ...` 같은 우회)이 영구 등록될 수 있음
- 우리가 user settings.json에 만든 deny가 local의 allow에 의해 무력화 가능

**해결**: auto 모드 도입 후엔 빈 깡통(`{"permissions":{"allow":[],"deny":[]}}`)으로 리셋. classifier가 알아서 처리. 본 레포의 `settings/settings.local.empty.json`을 그대로 복사하면 됨.

**예방**: 권한 프롬프트에서 "Allow once"만 누르고 "Always allow"는 정말 신중하게.

### 함정 #4: Windows의 기본 셸은 git-bash

**증상**: Claude Code의 `!` 접두어로 PowerShell 문법 쓰면 에러 (`/usr/bin/bash: ...command not found`)

**원인**: Windows에서도 Claude Code는 내장 git-bash(`/usr/bin/bash`)를 셸로 사용.

**올바른 문법**:
```bash
# A. bash 문법으로 환경변수
! echo $USERPROFILE      # 단, Windows의 $USERPROFILE은 git-bash에선 다를 수 있음
! echo $HOME             # 가장 안전

# B. PowerShell 명시 호출
! pwsh -Command '$env:USERPROFILE'
! pwsh -c "Get-Process"

# C. cmd 명시 호출
! cmd /c "echo %USERPROFILE%"
```

### 함정 #5: `autoUpdates`는 settings.json이 아니라 `~/.claude.json`에

**증상**: settings.json에 `"autoUpdatesChannel": "latest"` 박았는데 `/status`에선 `disabled (config)`

**원인**: Claude Code는 **자동 업데이트 마스터 스위치**를 `~/.claude.json`의 `autoUpdates` (bool)에서 관리. settings.json의 채널 설정은 보조.

**해결**:
```bash
sed -i.bak 's/"autoUpdates": false/"autoUpdates": true/' ~/.claude.json
```

**보너스**: `autoUpdatesProtectedForNative: true`는 네이티브 설치 보호 플래그. 그대로 두면 됨.

### 함정 #6: Max 플랜의 auto 모드는 Opus 4.7만 작동

**증상**: settings.json에 `defaultMode: auto` 박고 opt-in도 통과했는데 실제론 default처럼 작동

**원인 (Max 플랜)**: auto 모드는 Max에서는 **Opus 4.7 전용**. Opus 4.6, Sonnet 4.6, Haiku에서는 작동 안 함.

**다른 플랜**:
- Team/Enterprise/API: Sonnet 4.6, Opus 4.6, Opus 4.7 모두 OK
- Pro: auto 모드 자체가 미지원

**해결**:
1. Claude Code 버전이 2.1.111+ 인지 확인 (`claude --version`)
2. `/model`에서 Opus 4.7 선택
3. 다시 `/status`로 확인

### 함정 #7: 마켓플레이스/플러그인 호환성

**증상**: 플러그인 설치했는데 hook 에러나 일부 기능 미작동

**원인**: 일부 플러그인이 Windows 미지원

**오늘 검증된 호환성**:

| 플러그인 | 저장소 | Windows 지원 | 상태 |
|---|---|---|---|
| **omc** | Yeachan-Heo/oh-my-claudecode | ✅ | 32k stars, 19 agents + 36 skills, v4.13.6 (활발) |
| ~~TechDufus~~ | TechDufus/oh-my-claude | ❌ "Windows support is planned" | 피하기 |
| ssenart | ssenart/oh-my-claude | 미확인 | 검증 필요 |

---

## 5. 해결 방안 — Phase별 실행 절차

> **자동 실행**: 이 Phase 전체를 `scripts/apply-windows.ps1`이 idempotent하게 수행합니다. `pwsh scripts/apply-windows.ps1 -DryRun`으로 변경 미리 확인 가능. 아래는 수동 실행/이해용.

### Phase 1 — 진단 (5분)

새 컴퓨터에서 Claude Code 처음 실행 후, **현재 상태 파악**:

```powershell
# 1.1 버전 확인 (2.1.111+ 필수)
claude --version

# 1.2 핵심 파일 존재 여부
Test-Path "$env:USERPROFILE\.claude\settings.json"
Test-Path "$env:USERPROFILE\.claude\settings.local.json"
Test-Path "$env:USERPROFILE\.claude.json"
Test-Path "$env:ProgramData\ClaudeCode\managed-settings.json"   # 있으면 enterprise 환경

# 1.3 현재 자동 업데이트 상태
Get-Content "$env:USERPROFILE\.claude.json" | Select-String "autoUpdates"

# 1.4 환경변수 점검 (모두 비어있어야 정상)
$env:CLAUDE_CODE_DISABLE_AUTO_UPDATE
$env:DISABLE_AUTOUPDATER
```

버전이 낮으면:
```powershell
npm install -g @anthropic-ai/claude-code@latest
# 또는
claude update
```

### Phase 2 — 백업 (1분)

```powershell
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$base = "$env:USERPROFILE\.claude"

if (Test-Path "$base\settings.json") {
    Copy-Item "$base\settings.json" "$base\settings.json.bak.$ts"
}
if (Test-Path "$base\settings.local.json") {
    Copy-Item "$base\settings.local.json" "$base\settings.local.json.bak.$ts"
}
if (Test-Path "$env:USERPROFILE\.claude.json") {
    Copy-Item "$env:USERPROFILE\.claude.json" "$env:USERPROFILE\.claude.json.bak.$ts"
}
Write-Host "✅ 백업 완료 (.$ts)" -ForegroundColor Green
```

### Phase 3 — 적용 (10분)

#### 3.1 `~/.claude/settings.json` (user 설정)

본 레포의 `settings/user-settings.json`을 그대로 복사하거나, 다음과 동일:

```json
{
  "permissions": {
    "defaultMode": "auto",
    "allow": [
      "Edit(.commit_message.txt)",
      "Read",
      "Glob",
      "Grep",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(gh auth:*)",
      "Bash(gh repo:*)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(Remove-Item -Recurse -Force:*)",
      "Bash(rd /s /q:*)"
    ]
  },
  "extraKnownMarketplaces": {
    "omc": {
      "source": {
        "source": "git",
        "url": "https://github.com/Yeachan-Heo/oh-my-claudecode.git"
      }
    }
  }
}
```

PowerShell로 적용:
```powershell
$src = "$PSScriptRoot\..\settings\user-settings.json"   # 본 레포 기준 상대 경로
$dst = "$env:USERPROFILE\.claude\settings.json"
Copy-Item $src $dst -Force

try {
    Get-Content $dst -Raw | ConvertFrom-Json | Out-Null
    Write-Host "✅ settings.json 적용 + 검증 OK" -ForegroundColor Green
} catch {
    Write-Host "❌ JSON 오류! 백업으로 복원하세요" -ForegroundColor Red
}
```

> 💡 **hooks를 안 넣은 이유**: omc 플러그인이 commit message 자동 관리(`.commit_message.txt`)를 이미 해줘서 자체 hook은 redundant. 깨지기 쉬운 PowerShell hook 명령 작성보다 omc에 위임이 깔끔.
>
> Mac 트랙은 `hooks/deny-destructive-commands.py`(PreToolUse)를 추가로 사용. Windows에서도 Python 3가 있으면 동일하게 활용 가능하나 v1.0에서는 6개 deny 화이트리스트로 충분.

#### 3.2 `~/.claude/settings.local.json` (빈 깡통)

```powershell
$src = "$PSScriptRoot\..\settings\settings.local.empty.json"
Copy-Item $src "$env:USERPROFILE\.claude\settings.local.json" -Force
Write-Host "✅ settings.local.json 리셋 완료"
```

> 💡 누적된 일회성 allow가 없는 새 컴퓨터라면 이 단계 생략 가능.

#### 3.3 `~/.claude.json` (autoUpdates 활성화)

```powershell
$path = "$env:USERPROFILE\.claude.json"
if (Test-Path $path) {
    $content = Get-Content $path -Raw
    if ($content -match '"autoUpdates":\s*false') {
        $content = $content -replace '"autoUpdates":\s*false', '"autoUpdates": true'
        [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
        Write-Host "✅ autoUpdates: true 적용"
    } else {
        Write-Host "ℹ️ autoUpdates 이미 true이거나 키 없음"
    }
}
```

### Phase 4 — 검증 (5분)

Claude Code **완전 종료 → 새 세션**:

```powershell
claude
```

세션 안에서 슬래시 명령으로 검증:

```
/status      → Default permission mode: Auto mode, Model: Opus 4.7
/permissions → allow 11개, deny 6개
/plugin      → omc 마켓플레이스만
/model       → Opus 4.7 옵션 보이는지 (Max + 2.1.111+)
```

### Phase 5 — auto 모드 첫 활성화 (자동)

새 세션 첫 진입 시 prompt가 뜨면:

```
Enable auto mode?
❯ 1. Yes, and make it my default mode    ← 이거 선택
  2. Yes, enable auto mode
  3. No, exit
```

→ **1번 선택**. settings.json의 `defaultMode: auto`와 시너지.

이후 `~/.claude.json`에 `"skipAutoPermissionPrompt": true`가 자동 추가됨.

---

## 6. AI용 마스터 프롬프트

다른 머신의 Claude Code(또는 다른 AI)에게 던질 수 있는 **셋업 위임 프롬프트**는 본 레포의 별도 파일로 분리되어 있습니다:

→ **`prompts/master-setup-prompt.md`** 통째 복사해서 사용

활용 시나리오는 그 파일 안에 정리되어 있습니다.

---

## 7. 장애 요인 및 트러블슈팅

### 7.1 자주 마주치는 에러 매트릭스

| 증상 | 원인 | 해결 |
|---|---|---|
| `/model` picker에 Opus 4.7 없음 | Claude Code 버전 < 2.1.111 | `npm install -g @anthropic-ai/claude-code@latest` |
| `/status`에 `Auto-update channel: disabled (config)` | `~/.claude.json`의 `autoUpdates: false` | sed로 true 변경 |
| Auto mode 켰는데 매번 권한 물어봄 | 모델이 Opus 4.7 아님 (Max 플랜) | `/model`로 Opus 4.7 선택 |
| PostToolUse hook 에러 (`:USERPROFILE not recognized`) | PowerShell single quote 변수 미확장 | hooks 키 통째 제거 (omc에 위임) |
| `! command` 에러 (`/usr/bin/bash: line 1`) | bash 문법 사용 안 함 | `$VAR` 또는 `pwsh -c "..."` |
| python3 → "Python"만 출력 | Windows MS Store 리다이렉트 | `node`나 PowerShell `ConvertFrom-Json` 사용 |
| jq command not found | git-bash에 jq 미설치 | PowerShell `ConvertFrom-Json` 또는 `node -e "..."` |
| classifier가 PowerShell 변수 접근 차단 | 보수적 판단 | 그대로 두기 (안전 우선) or 자주 막히는 패턴만 allow 추가 |
| 마켓플레이스에 oh-my-claude 여러 개 등록 | 과거 시도 흔적 | settings.json에서 `omc`만 유지하고 나머지 제거 |

### 7.2 JSON 편집 도구 선택 트리

```
JSON 편집 필요
├─ python3 있나? → 있으면 사용
├─ 없으면 jq 있나? → 있으면 사용
├─ 없으면 node 있나? → 있으면 (omc 깔려있으면 100% 있음)
└─ 다 없으면 PowerShell ConvertFrom-Json / ConvertTo-Json (가장 안전)
```

#### PowerShell ConvertFrom-Json으로 키 제거 예시
```powershell
$path = "$env:USERPROFILE\.claude\settings.json"
$json = Get-Content $path -Raw | ConvertFrom-Json
$json.PSObject.Properties.Remove('hooks')   # hooks 키 제거
$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
```

#### Node로 키 제거 예시
```bash
node -e "const fs=require('fs'); const p=process.env.USERPROFILE+'/.claude/settings.json'; const s=JSON.parse(fs.readFileSync(p)); delete s.hooks; fs.writeFileSync(p, JSON.stringify(s, null, 2))"
```

### 7.3 롤백 — 한 줄로

```powershell
# 가장 최근 백업으로 복원
Get-ChildItem "$env:USERPROFILE\.claude\settings.json.bak.*" |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1 |
  Copy-Item -Destination "$env:USERPROFILE\.claude\settings.json" -Force
```

---

## 8. 검증 체크리스트

### 8.1 셋업 직후 (필수)

- [ ] `claude --version` ≥ 2.1.111
- [ ] `/status` → `Default permission mode: Auto mode`
- [ ] `/status` → `Model: Opus 4.7` (Max 플랜)
- [ ] `/status` → `Login method: Claude Max Account`
- [ ] `/permissions` → allow 11개, deny 6개 정확히 표시
- [ ] `/plugin` → marketplace `omc` 1개만
- [ ] `/hooks` → 항목 없음 (의도된 비어있음)

### 8.2 실전 작동 테스트

- [ ] **Test A**: `test.md 만들고 "hello"라고 써줘` → 권한 프롬프트 없이 즉시 생성
- [ ] **Test B**: `rm -rf test.md` 실행 시도 → "Permission denied" 표시
- [ ] **Test C**: `sudo whoami` 실행 시도 → 거부
- [ ] **Test D**: omc 활성화 시 `.commit_message.txt` 자동 갱신 확인
- [ ] **Test E**: PostToolUse hook 에러 메시지 없음

### 8.3 1주일 후 정기 점검

- [ ] `claude --version` (자동 업데이트 작동 확인)
- [ ] `/fewer-permission-prompts` 실행 → allowlist 추천 검토
- [ ] settings.local.json 크기 확인 (5kB 미만 유지)
- [ ] 백업 파일 정리 (한 달 이상 된 것 삭제)

---

## 9. 확장 경로 (What If)

### 9.1 일주일 후 — Allow 자동 큐레이션

```
/fewer-permission-prompts
```

세션 히스토리 스캔 → 자주 막혔던 안전 명령 자동 추천. 빈 깡통이었던 `settings.local.json`이 실사용 기반으로 채워짐.

### 9.2 omc Ultrawork 모드 활용

omc 플러그인의 진짜 가치는 19개 specialized agents의 병렬 실행. 첫 시도:

```
ultrawork [실제 작업 설명] — 분석 + 개선안 3개
```

ThinkingOS의 cognitive lens(NDM/Cynefin/Prism)와 결이 맞춰지는지 비교 가치 있음.

### 9.3 멀티 머신 동기화 (이 레포가 SST)

본 레포 `claude-code-setup`이 멀티머신 셋업의 단일 진실원천(SST)입니다. 현재 fleet은 `FLEET.md` 참고.

```
claude-code-setup/
├─ FLEET.md                 ← 현재 머신 인벤토리 (변경 시 여기만)
├─ settings/
│  ├─ user-settings.json    ← 모든 머신 공통
│  └─ machines/<id>/        ← 머신별 override (필요시)
├─ playbooks/
│  ├─ windows-setup.md      ← (이 문서)
│  └─ macos-setup.md
└─ scripts/
   ├─ apply-windows.ps1     ← Windows 자동 적용
   ├─ bootstrap-windows.ps1 ← 새 Windows 머신 원라이너
   └─ bootstrap-mac.sh      ← Mac (기존 트랙)
```

- 변경 시 git pull로 전체 반영
- 머신별 차이(셸, 경로)는 `settings/machines/<id>/` 또는 OS별 플레이북에서만 처리
- Mac은 추가로 `cl`/`clp`/`clr` aliases + `cmux` SSH handoff (`docs/user-guide-detailed.md` 참고)

### 9.4 N8N 연동 자동화 트리거

PostToolUse hook 자리에 N8N webhook 호출을 끼우면:
- Claude Code 편집 → N8N 파이프라인 트리거
- Obsidian 자동 인덱싱
- 콘텐츠 큐 푸시
- NAS 백업 트리거

⚠️ 다만 hook은 깨지기 쉬우니 **외부 스크립트 파일**로 빼고 hook에서는 그 스크립트만 호출.

### 9.5 프로젝트별 차별화

전역 설정은 깔끔하게 유지하고, 프로젝트별 특수성은 `.claude/settings.json` (프로젝트 폴더)에서 처리:

- **PoliScope** (Rails 8): 깔끔한 git 히스토리 필요 → hooks 없음, 수동 commit
- **어반정글 콘텐츠**: 빠른 이터레이션 → PostToolUse로 auto-commit OK
- **N8N 워크플로**: webhook 호출 hook 추가

---

## 10. 부록 — 레퍼런스

### 10.1 슬래시 명령 치트시트

| 명령 | 용도 |
|---|---|
| `/status` | 전체 설정 상태 한 화면 |
| `/permissions` | allow/deny 리스트 + 현재 모드 |
| `/hooks` | 등록된 hook 목록 |
| `/plugin` | 설치된 플러그인 + 마켓플레이스 |
| `/model` | 모델 선택 picker |
| `/config` | 설정 변경 메뉴 (인터랙티브) |
| `/exit` | 세션 종료 |
| `/continue` 또는 `claude -c` | 가장 최근 세션 이어가기 |
| `/resume` 또는 `claude -r` | 세션 picker로 선택 재개 |
| `/rewind` | 체크포인트로 롤백 |
| `/compact` | 컨텍스트 압축 |
| `/fewer-permission-prompts` | 자주 막힌 명령 → allowlist 추천 |

### 10.2 핵심 파일 위치 맵 (Windows)

```
C:\Users\<USER>\
├─ .claude.json                                 ← autoUpdates, 사용자 환경
├─ .claude\
│   ├─ settings.json                            ← 권한/hooks/마켓플레이스 (user level)
│   ├─ settings.local.json                      ← 일회성 allow 누적 (user level)
│   ├─ CLAUDE.md                                ← 사용자 시스템 메모리
│   ├─ history.jsonl                            ← 모든 대화 히스토리
│   ├─ projects\<프로젝트-인코딩>\<sessionid>.jsonl  ← 프로젝트별 세션
│   ├─ hooks\                                   ← (선택) hook 스크립트
│   ├─ plugins\                                 ← omc 등 플러그인 캐시
│   ├─ commands\                                ← 커스텀 슬래시 명령
│   └─ todos\                                   ← Todo 추적
```

### 10.3 안전한 명령 vs 위험한 명령

#### ✅ allow에 추가 OK (대부분 안전)
- `Read`, `Glob`, `Grep` — 읽기만
- `Bash(git status:*)`, `Bash(git diff:*)`, `Bash(git log:*)` — git 정보 조회
- `Bash(npm test:*)`, `Bash(pytest:*)` — 테스트 실행
- `Bash(ls:*)`, `Bash(cat:*)` — 파일 정보

#### ⚠️ 신중하게 (상황 따라)
- `Bash(npm install:*)` — 외부 패키지 설치 (공급망 공격 위험)
- `Bash(git push:*)` — 원격 영향
- `Edit(*)` — 와일드카드는 위험
- `Bash(pwsh -c:*)` — PowerShell 직접 호출 (자유도 큼)

#### ❌ deny에 박아두기 (절대 금지)
- `Bash(rm -rf:*)` — 폴더 통째 삭제
- `Bash(sudo:*)` — 시스템 권한
- `Bash(git push --force:*)`, `Bash(git push -f:*)` — 히스토리 덮어쓰기
- `Bash(Remove-Item -Recurse -Force:*)` — Windows 폴더 강제 삭제
- `Bash(rd /s /q:*)` — cmd 강제 삭제

### 10.4 공식 문서

- Claude Code Permission Modes: https://code.claude.com/docs/en/permission-modes
- Hooks Reference: https://code.claude.com/docs/en/hooks
- Sessions: https://code.claude.com/docs/en/agent-sdk/sessions
- CLI Reference: https://docs.anthropic.com/en/docs/claude-code/cli-reference
- omc 플러그인: https://github.com/Yeachan-Heo/oh-my-claudecode

### 10.5 오늘 실제 배운 것 (Lessons Learned, 2026-05-20)

> alive의 첫 셋업에서 발견한 것들. 다음 셋업에선 함정 #1~#7이 사전에 회피되어 시간 절약.

1. **설정 파일은 5계층** — 단일 파일이 아님. 어디 박혀있는지부터 파악.
2. **자동 업데이트는 별도 파일** — settings.json의 `autoUpdatesChannel`은 종속, `~/.claude.json`의 `autoUpdates`가 진짜 마스터.
3. **hooks는 신중하게** — Stop matcher 오용, PowerShell 변수 확장 등 함정 다수. omc가 commit 관리하면 자체 hook 불필요.
4. **classifier는 보수적** — auto 모드라도 PowerShell 직접 호출 같은 자유도 큰 명령은 막힘. 정상이고, allow로 점진적 보완.
5. **백업은 무조건, 타임스탬프** — 5번의 변경 = 5개의 백업. 한 달 후 정리.
6. **검증은 새 세션에서** — 모든 변경은 재시작 후 반영.
7. **마켓플레이스 호환성 확인** — Windows 미지원 플러그인은 시간 낭비.

---

## 🏁 마무리

이 플레이북은 **2026-05-20 alive의 첫 Windows + Claude Max + Opus 4.7 셋업 경험**을 응축한 결과입니다.

다음 사람(또는 다음 자신)이 같은 길을 다시 헤매지 않도록, 30분짜리 셋업이 진짜 30분에 끝나도록.

> **버전 히스토리**
> - v1.0 (2026-05-20): 초안. Windows + Max + Opus 4.7 기준. (이 레포의 `CHANGELOG.md`도 함께 참고)
> - v1.1 (예정): omc ultrawork 실전 패턴, Python hook의 Windows 포팅 검토.

---

*macOS 트랙은 `playbooks/macos-setup.md` (또는 기존 `docs/user-guide-detailed.md`) 참고.*
