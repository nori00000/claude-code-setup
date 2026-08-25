# Changelog

이 레포의 주요 변경 이력. 머신 인벤토리는 `FLEET.md` 참고.

## [Unreleased]

### Verified — 문서-코드 정합성 정기 재검증 (2026-07-27 ~ 2026-08-25)
- 이 기간 doc-sync 에이전트가 전 범위(README·FLEET·PROJECT·NOTICE·PUBLICATION_REVIEW·scripts/·hooks/·settings/·templates/·docs/·playbooks/)를 반복 재검증 — 코드/문서 변경 0건, 신규 MISMATCH·STALE_DOC·UNDOCUMENTED 0건.
- 유일한 미해결 항목: `FLEET.md`의 `mac-m4-studio`(표 ID) vs `m4-studio`(`hostname -s` 실측) 불일치. 2026-07-19 발견, homelab-orchestration·dev-retrospective까지 걸친 크로스레포 리네임이라 사용자 SSOT 결정 대기.
- (일별 "변경 없음" 재검증 기록 ~20건을 이 항목 1건으로 압축 — 상세 이력은 git.)

### Fixed — 문서-코드 정합성 검증 (2026-07-22)
- `README.md` — "안전망 구조" 표가 Mac/Windows 모두 "Allow 11개·Deny 6개로 동일"이라 표기했던 것을 정정. 실측(`scripts/bootstrap-mac.sh:129-136`, `scripts/install-hooks.sh:180-208`)상 Mac은 allow 15개(도구/카테고리 단위)를 직접 기록하고 deny 배열은 아예 생성하지 않음(Python hook이 대체) — 11개/6개는 Windows 트랙(`settings/user-settings.json`) 전용값. 같은 README의 Quick Start 섹션(line 80)과 `docs/user-guide-detailed.md:59`는 이미 Mac의 정확한 15개 목록을 기술하고 있어, 표만 내부적으로 모순됐던 것을 표만 정정
- 그 외 전수 재검증(스크립트 실행권한·훅 정규식 8패턴·JSON 스키마·`.gitignore`·`.claude/settings.json`·marketplaces·devlog·shell 함수 5개·env var·blueprint 감지·apply-windows.ps1 permissions 라인) — 위 1건 외 추가 MISMATCH 없음

### Fixed — 문서-코드 정합성 검증 (2026-07-21)
- `scripts/install-hooks.sh`, `scripts/install-codex-companion.sh` — git 추적 파일 모드가 `100644`(실행 불가)였던 것을 `chmod +x`로 정정 (README.md/docs/user-guide-*.md가 두 스크립트를 `bash` 접두어 없이 `~/claude-code-setup/scripts/install-hooks.sh` 형태로 직접 실행하도록 안내하는데, 실행 비트가 없으면 Permission denied — 나머지 8개 `.sh` 스크립트는 이미 `100755`로 일관됨)
- 그 외 전수 재검증(README·PROJECT·NOTICE·PUBLICATION_REVIEW·FLEET·OWNERSHIP·CHANGELOG·devlog·docs/·playbooks/·prompts/·settings/·templates/·scripts/·hooks/·.gitignore·.claude/settings.json·marketplaces/) — 위 1건 외 추가 MISMATCH 없음

### Fixed — 문서-코드 정합성 검증 (2026-07-20)
- `prompts/master-setup-prompt.md` — 임베드된 `settings.json` allow 목록이 9개(구버전)로 정체되어 있던 것을 11개로 정정 (`Bash(gh auth:*)`, `Bash(gh repo:*)` 누락 — `settings/user-settings.json`·`playbooks/windows-setup.md`는 이미 11개로 일치, 이 파일만 07-18 정정에서 누락됐던 것)
- `playbooks/macos-setup.md` — 머신 ID 상태 `(셋업 중)` → `(✅ Active)`로 정정 (FLEET.md가 2026-07-19에 이미 갱신했으나 이 stub 문서는 반영 안 됨)
- 그 외 전수 재검증(스크립트 CLI 플래그·훅 정규식·JSON 스키마·.gitignore·devlog) — 위 2건 외 추가 MISMATCH 없음

### Fixed — 문서-코드 정합성 검증 (2026-07-19)
- `FLEET.md` — `mac-m4-studio` 스펙 확정(Apple M4 Max, Mac Studio, macOS 26.5.2 — `sysctl`/`system_profiler` 직접 확인) 및 상태 `🔧 Setup 중` → `✅ Active` 정정 (이 세션의 homelab 핸드오프 기준 태스크 39건·상시 launchd 다수 확인, 수 주 이상 실사용 중인 상태와 불일치했음)
- `FLEET.md` — 실측 호스트명(`m4-studio`)과 표의 ID(`mac-m4-studio`) 불일치 발견 및 주석 표기 (크로스레포 영향으로 자동 리네임은 보류, 사용자 판단 필요)
- 그 외 스크립트/훅/설정 파일 전수 검증(README·CHANGELOG·PROJECT·NOTICE·PUBLICATION_REVIEW·devlog·docs/·playbooks/·prompts/·settings/·templates/) — MISMATCH 추가 발견 없음

### Fixed — 문서-코드 정합성 검증 (2026-07-18)
- `README.md` — "Allow 화이트리스트 9개" → 11개로 정정 (`settings/user-settings.json`의 실제 allow 항목 수와 불일치했음)
- `PUBLICATION_REVIEW.md` — Worktree 필드의 누락된 닫는 백틱 수정

### Added — 공개 준비 & 히스토리 정리 (2026-07-13)
- `PROJECT.md` — 한영 프로젝트 요약, 키워드, 저작권/재사용 범위
- `NOTICE.md` — 소스코드(MIT)/문서(CC BY 4.0) 라이선스 고지, 제외 대상 명시
- `PUBLICATION_REVIEW.md` — 공개 준비 점검표 및 검증 결과 기록
- `OWNERSHIP.md` — 포트폴리오 규율 메타데이터 (role/layer/tier/owner 등)
- 히스토리 재작성: 단일 sanitized root 커밋으로 재공개 (기존 공개 히스토리 제거, pre-rewrite 미러는 비공개 보관)

### Added — tmux 워크플로우 매뉴얼 (2026-05-22)
- `playbooks/tmux-claude-code-workflow.md` — Windows WSL2 + Claude Code/Codex tmux 실전 매뉴얼 (단축키 표, 원격/모바일 접속 포함)

### Added — Windows 트랙 (2026-05-20)
- `playbooks/windows-setup.md` — Windows + Claude Max + Opus 4.7 셋업 플레이북 v1.0
- `settings/user-settings.json` — auto mode + 6개 deny + omc 마켓플레이스 (모든 머신 공통)
- `settings/settings.local.empty.json` — 누적된 allow 리셋용 깡통
- `settings/machines/win-i9-4070/` — 머신별 override 슬롯
- `scripts/bootstrap-windows.ps1` — 새 Windows 머신 한 줄 셋업
- `scripts/apply-windows.ps1` — Phase 1~5 자동화 (--dry-run, idempotent)
- `scripts/diagnose-windows.ps1` — 진단만 (Phase 1)
- `prompts/master-setup-prompt.md` — 다른 머신의 Claude Code에게 던질 셋업 위임 프롬프트
- `marketplaces/omc-snippet.json` — omc 마켓플레이스 등록 조각
- `FLEET.md` — 현재 머신 인벤토리 SST
- `README.md` 인덱스 섹션 prepend (기존 Mac 트랙 본문은 그 아래 유지)

### Notes
- 기존 Mac 트랙(`bootstrap-mac.sh`, `cl`/`clp`/`clr`, `hooks/deny-destructive-commands.py`, `docs/user-guide-*.md`)은 손대지 않음.
- `playbooks/macos-setup.md`는 stub. 다음 라운드에서 기존 `docs/` 자료 흡수·재구성.
- 안전망 이중화: Python PreToolUse hook(기존) + auto mode classifier + 6개 deny 화이트리스트(신규). 충돌 아님.

## [Initial]

### v1.0 (2026-04-09) — Mac 트랙 초안
- `scripts/bootstrap-mac.sh`, `install-shell-integration.sh`, `install-hooks.sh` 등
- `hooks/deny-destructive-commands.py` (Python PreToolUse hook, 8개 명령 차단)
- `templates/manifest.schema.json`, `project-profile.md`
- `docs/user-guide-{detailed,simple}.md`
- cmux + tmux + SSH handoff 워크플로
- 자세한 내용은 `docs/user-guide-detailed.md` §14 참고.
