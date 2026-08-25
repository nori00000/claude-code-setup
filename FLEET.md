# FLEET — 현재 머신 인벤토리

> **마지막 업데이트**: 2026-07-19 (doc-sync 검증: 스펙 확정, 상태 갱신)
> **목적**: claude-code-setup, homelab-orchestration 등 멀티머신 작업의 단일 진실원천(SST). 머신 변동 시 **이 파일만** 업데이트하면 다른 문서·스크립트는 그대로 참조.

## 머신 명명 규칙

```
{os-약어}-{cpu}-{gpu|form}

예시:
  win-i9-4070       Windows + Intel i9 + RTX 4070
  mac-m4-studio     macOS + M4 칩 + Studio 폼팩터
  mac-m1-mini       macOS + M1 칩 + Mini 폼팩터
```

원칙:
- 짧고 식별 가능. `farm-` 같은 위치 접두사는 **붙이지 않는다** (이전·재배치에 약함).
- 칩(`m4`, `i9`)으로 세대 식별, GPU·폼팩터로 모델 구분.
- 호스트명·폴더명·`.claude/project-profile.md`의 `last_machine` 필드 모두 같은 이름 사용.

## 현재 활성 머신

| ID | OS | 핵심 스펙 | 역할 | 위치 | 상태 |
|---|---|---|---|---|---|
| `win-i9-4070` | Windows 11 | Lenovo Legion (82WK), i9-13900HX, RTX 4070 Laptop, 32GB | Dev workstation | 농장(사무실) | ✅ Active |
| `mac-m4-studio` | macOS 26.5.2 | Mac Studio, Apple M4 Max | 중앙 컴퓨트·오케스트레이션 | 농장 | ✅ Active <!-- DOC-SYNC: 2026-07-19 검증 — `sysctl`/`system_profiler` 직접 실행으로 스펙 확정(M4 Max, Mac Studio). 상태는 "Setup 중"→"Active"로 정정: 이 세션의 homelab 핸드오프에 이 머신 기준 진행 중 태스크 39건, 상시 가동 launchd(cron) 다수, `.omc/`·`~/reports/` 등 수개월치 운영 흔적 확인 — 최소 수 주간 실사용 중인 상태와 불일치. 단, "언제부터 Active였는지"는 codebase만으로 확정 불가(INFERRED). -->

## Pending / 검토 중

| ID | 상태 | 비고 |
|---|---|---|
| `mac-m1-mini` 등 | ⏸️ Pending | 농장 이전 후 역할 재정의 필요. 셋업 시 이 표에 추가 |

## 은퇴 / 매각

| ID | 사유 | 날짜 |
|---|---|---|
| `dgx-spark` | 매각 — 역할은 `mac-m4-studio`가 이어받음 | 2026-05 |

## 변경 로그

- **2026-05-20**: 초안. DGX Spark 매각 기록. 농장(사무실) 이전 진행 중이라 fleet 유동적. `win-i9-4070` + `mac-m4-studio` 2대로 셋업 우선순위 설정.
- **2026-07-19** (doc-sync): `mac-m4-studio` 스펙 확정(Apple M4 Max, Mac Studio, macOS 26.5.2) 및 상태 `🔧 Setup 중` → `✅ Active` 정정. 호스트명(`m4-studio`) vs 표 ID(`mac-m4-studio`) 불일치 발견 — 크로스레포 영향으로 자동 리네임은 보류.

## 다른 레포에서의 참조

- `homelab-orchestration` 레포가 머신 인벤토리를 참조하면 **이 파일을 SST로 사용** (중복 정의 금지).
- `dev-retrospective/data/machines/<id>/` 폴더명도 이 표의 ID를 따른다.
- Mac 가이드 `docs/user-guide-detailed.md`에 등장하는 예시 머신명(`studio`, `air`, `pro`)은 stale — 새 작업은 이 표 기준.

<!-- DOC-SYNC: 2026-07-19 발견 — `hostname -s` 실측값은 `m4-studio`(접두사 `mac-` 없음)이나 이 표의 ID는 `mac-m4-studio`. 20행의 "호스트명·폴더명·last_machine 모두 같은 이름 사용" 원칙과 실측이 불일치. homelab-orchestration 핸드오프 문서들도 실측과 같이 `m4-studio`로 일관 표기 중이라, 이 표의 ID가 stale일 가능성이 높음(INFERRED). 다만 ID 변경은 homelab-orchestration·dev-retrospective 등 참조 레포까지 걸친 크로스레포 결정이라 이 레포 단독으로 자동 수정하지 않음 — 사용자 확인 후 일괄 리네임 권장. -->
