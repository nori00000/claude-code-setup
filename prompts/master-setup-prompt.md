# 마스터 셋업 프롬프트 (Windows)

다음 컴퓨터의 Claude Code(또는 다른 AI)에게 던질 수 있는 **셋업 위임 프롬프트**. 통째로 복사해서 사용.

자세한 배경은 `playbooks/windows-setup.md` 참고.

---

````markdown
당신은 Windows PC에서 Claude Code를 처음 셋업하는 작업을 도와야 합니다.
아래 플레이북에 따라 단계별로 진행해주세요.

## 사용자 정보
- Claude Max 플랜
- 새 Windows PC (Windows 10/11)
- PowerShell 사용 가능, git-bash는 Claude Code 내장
- 사용자는 ADHD 성향이라 20분 단위 액션 + 시각적 구분 선호

## 셋업 목표
1. Auto mode 활성화 (classifier 기반 자동 권한 처리)
2. Deny 안전벨트 (rm -rf, sudo, force push 등 차단)
3. omc 플러그인 (Yeachan-Heo/oh-my-claudecode) 설치 가능 환경
4. 자동 업데이트 활성화
5. PostToolUse hook 안 만들기 (omc가 commit 관리 담당)

## 진행 순서

### Step 1: 진단
다음을 확인하고 사용자에게 보고:
- claude --version (2.1.111 이상 필수)
- ~/.claude/settings.json 존재 여부 및 내용
- ~/.claude/settings.local.json 존재 여부 및 크기
- ~/.claude.json의 autoUpdates 값
- 환경변수 CLAUDE_CODE_DISABLE_AUTO_UPDATE 등

### Step 2: 백업
타임스탬프 형식(yyyyMMdd-HHmmss) 백업 파일 생성:
- settings.json → settings.json.bak.{ts}
- settings.local.json → settings.local.json.bak.{ts}
- .claude.json → .claude.json.bak.{ts}

### Step 3: settings.json 적용
다음 JSON으로 ~/.claude/settings.json 통째 교체:

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
      "Bash(git commit:*)"
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

⚠️ 절대 hooks 키를 추가하지 마세요. omc가 commit 자동 관리합니다.

### Step 4: settings.local.json 리셋
~/.claude/settings.local.json을 `{"permissions":{"allow":[],"deny":[]}}` 로 덮어쓰기.

### Step 5: autoUpdates 활성화
~/.claude.json에서 "autoUpdates": false → true 변경.

### Step 6: JSON 유효성 검증
세 파일 모두 ConvertFrom-Json으로 파싱 가능한지 확인.

### Step 7: 사용자에게 안내
- Claude Code 종료 후 재실행 필요함 안내
- "Enable auto mode?" 프롬프트 뜨면 1번(default mode로) 선택 안내
- /model에서 Opus 4.7 선택 안내 (필수, auto 모드 작동 조건)

## 절대 하지 말 것
- hooks 키 추가 (Stop matcher 사용 또는 PostToolUse with PowerShell variable expansion)
- TechDufus/oh-my-claude 또는 ssenart/oh-my-claude 마켓플레이스 추가 (Windows 미지원 또는 미검증)
- 백업 없이 변경
- JSON 검증 없이 다음 단계 진행

## 막히면
- python3, jq 같은 도구가 없을 수 있음. PowerShell의 ConvertFrom-Json / ConvertTo-Json 또는 node로 대체.
- PostToolUse hook 에러 발생 시 hooks 키 통째로 제거 (PowerShell ConvertFrom-Json + PSObject.Properties.Remove 사용)

## 성공 기준 (사용자에게 검증 요청)
- /status → Default permission mode: Auto mode, Model: Opus 4.7
- 일반 파일 생성 시 권한 프롬프트 없음
- "rm -rf test.md" 명령은 거부됨
````

---

## 활용 시나리오

**시나리오 A**: 새 컴퓨터에서 Claude Code 처음 켰을 때
1. 위 프롬프트 통째 복사
2. `claude` 실행 → 첫 메시지로 붙여넣기
3. AI가 단계별로 진행

**시나리오 B**: 누군가에게 셋업 부탁할 때 (or 다른 AI에게)
1. 위 프롬프트 + "다 자동으로 해주고 마지막에 검증 결과만 보여줘" 추가
2. 결과 확인

**시나리오 C**: 위 프롬프트가 복잡하면, `scripts/apply-windows.ps1`을 그냥 실행하라고 안내:
```powershell
gh repo clone nori00000/claude-code-setup; cd claude-code-setup; pwsh scripts/apply-windows.ps1
```
