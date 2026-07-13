# 모바일 개발 환경 구축 및 레포 정리

- **날짜**: 2026-04-12
- **프로젝트**: claude-code-setup (+ my-context, mobile-dev-on-claude-code)
- **브랜치**: main

## 작업 요약

- Android Termux → Mac SSH로 Claude Code 세션을 이어가는 워크플로 정립
- 신규 GitHub 레포 `mobile-dev-on-claude-code` 생성 (Obsidian 노트 6개 동기화 + sync 스크립트)
- 공개 레포 6개 private 전환, `my-context`에서 금융정보 삭제
- `my-context/dev-setup.sh` → `claude-code-setup/scripts/bootstrap-mac.sh` 이식, hook 설치 순서 강제로 auto 모드 안전성 확보
- `_cl_tmux_wrap` 버그 재수정 (send-keys 기반 자동 claude 실행)

## 변경된 파일 (claude-code-setup 기준)

| 파일 | 변경 | 설명 |
|------|------|------|
| `scripts/bootstrap-mac.sh` | 생성 | Homebrew → Claude Code → OMC → tmux → hook → aliases → auto 모드 |
| `scripts/check-cmux-health.sh` | 생성 | cmux + claude 건강 체크 (exit 0/10/20) |
| `scripts/sync-current-branch.sh` | 생성 | codex-setup에서 이식 |
| `scripts/ssh-main-mac-project.sh` | 생성 | codex-setup에서 이식 |
| `scripts/install-shell-integration.sh` | 수정 | `_cl_maybe_tmux` 리팩터링 + send-keys 자동 실행 |
| `README.md` | 수정 | bootstrap 플로우 + 5단계 운영 플로우 |
| `docs/user-guide-detailed.md` | 수정 | Section 8 (codex-setup 정렬) 추가 |
| `docs/user-guide-simple.md` | 수정 | 헬퍼 스크립트 표 추가 |

## 핵심 결정

- **bootstrap 순서 고정**: 단계 4(hook) → 단계 6(auto 모드). hook이 깔리기 전에는 auto 모드 활성화 금지.
- **tmux 래핑 재설계**: `new-session -d` + `send-keys`로 한 번의 `cl` 호출이 claude까지 자동 실행하도록 변경 (이전 빈 셸 방식 폐기).
- **Private 레포 기반 bootstrap**: `curl | bash` 대신 `gh auth + git clone + bash` 3줄. 보안 > 1줄 편의성.

## 배운 점 (TIL)

- Private 레포의 raw URL은 curl로 가져올 수 없다 (401) — 1줄 bootstrap은 public 노출의 대가
- SSH 비대화형 셸은 `~/.zshrc`를 읽지 않음 → 원격 명령으로 shell 함수 호출 불가
- zsh `${(q)}`는 한글 인자 shell-quote의 가장 간결한 방법
- tmux `new-session -d` + `send-keys`는 race 거의 없음 (zsh 입력 버퍼가 처리)

## 후속 작업

- [ ] 새 Mac에서 `bootstrap-mac.sh` end-to-end 테스트
- [ ] git 히스토리에서 `경력증명-이상민.md` 완전 제거 (BFG)
- [ ] 스마트폰 첫 실전 작업 로그 추가
- [ ] `sync-from-obsidian.sh --watch` 모드 검토
