# win-i9-4070 머신별 override

이 폴더는 `win-i9-4070` 머신(Lenovo Legion 82WK / i9-13900HX / RTX 4070 Laptop)의 **선택적 override**를 둘 자리.

기본은 비어있고, 공통 `settings/user-settings.json`로 충분합니다. 이 머신에서만 다른 값이 필요할 때:

- `overrides.json` — `settings.json`에 머지될 머신 한정 키
- `notes.md` — 이 머신에서 만난 함정/예외 메모

> ID 명명은 `FLEET.md`의 규칙을 따른다. 호스트명 바꾸면 폴더명도 같이 git mv.
