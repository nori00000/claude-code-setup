# Claude Code on macOS — 셋업 플레이북 (stub, v0.1)

> **상태**: stub. v1.0은 다음 라운드에 작성 예정 — 기존 `docs/user-guide-detailed.md`의 자료를 흡수·재구성하고 Windows 플레이북과의 권장값(auto mode, deny 리스트, Opus 4.7)을 통일.

## 당분간은

새 Mac 셋업하려면 두 자료를 함께 보세요:

1. **`docs/user-guide-detailed.md`** — Mac 트랙의 정식 가이드. `bootstrap-mac.sh`, `cl`/`clp`/`clr` aliases, cmux + tmux + SSH handoff, Python hook 설치 등.
2. **`playbooks/windows-setup.md`** — auto mode, 5계층 설정, 6개 deny, omc 마켓플레이스 권장값. 셸·경로 차이만 무시하면 Mac에도 80% 적용.

## v1.0에서 검증 + 추가할 항목

- [ ] auto mode가 macOS에서도 동일하게 작동 (Opus 4.7 + Max 플랜 조건 동일?)
- [ ] omc 플러그인이 macOS에서 `.commit_message.txt` 자동 갱신 패턴 동일한지
- [ ] `~/.claude.json`의 `autoUpdates` 키가 macOS에서도 마스터 스위치인지
- [ ] 기존 `hooks/deny-destructive-commands.py`와 `settings/user-settings.json`의 6개 deny 사이 중복/충돌 정리 (이중 안전망 vs 단일화)
- [ ] `bootstrap-mac.sh`에 `settings/user-settings.json` 자동 적용 단계 추가 (현재는 install-hooks.sh에서 일부만)
- [ ] `cl`/`clp`/`clr` aliases의 auto mode 시대 재정의 (자동 프롬프트와 auto mode의 역할 분담)
- [ ] FLEET.md 기반 머신 ID로 `last_machine` 필드 정렬

## v1.0 작성 시 참고할 Windows 플레이북 섹션

- §2 설정 5계층 — macOS도 동일하나 경로만 `~/.claude/...`
- §4 함정 #1, #3, #5, #6, #7 — macOS에도 그대로 적용
- §4 함정 #2, #4 — Windows/PowerShell 한정. Mac은 zsh
- §5 Phase 1~5 — Mac은 PowerShell이 아니라 zsh 스크립트로 재작성
- §6 마스터 프롬프트 — Mac용 변형은 `prompts/`에 추가

## 머신 ID

`FLEET.md` 참고. 현재 활성: `mac-m4-studio` (셋업 중).
