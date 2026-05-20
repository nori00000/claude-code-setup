# Changelog

이 레포의 주요 변경 이력. 머신 인벤토리는 `FLEET.md` 참고.

## [Unreleased]

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
