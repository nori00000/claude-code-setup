# Tmux + Yazi on Windows via WSL

> Windows 개발환경에서 tmux와 yazi를 안정적으로 쓰기 위한 WSL Ubuntu 기준 플레이북.

## 결론

Windows PowerShell에서 tmux를 직접 쓰는 방식은 권장하지 않는다. 실전 구성은 아래 흐름이다.

```text
Windows Terminal -> WSL Ubuntu -> tmux -> yazi
```

## 설치 전 확인

PowerShell에서 WSL 상태를 확인한다.

```powershell
wsl --list --verbose
```

Ubuntu가 보이면 바로 실행한다.

```powershell
wsl -d Ubuntu
```

Ubuntu가 없으면 설치한다.

```powershell
wsl --install Ubuntu
```

설치 후 Windows가 재부팅을 요구하면 재부팅한다.

## 레포에서 설치하기

Ubuntu/WSL 안에서 실행한다.

```bash
git clone https://github.com/nori00000/claude-code-setup.git ~/claude-code-setup
cd ~/claude-code-setup
chmod +x scripts/setup-tmux-yazi.sh
bash scripts/setup-tmux-yazi.sh
```

로컬에 이미 레포가 있으면 clone 대신 pull만 한다.

```bash
cd ~/claude-code-setup
git pull --ff-only
bash scripts/setup-tmux-yazi.sh
```

## 설치되는 것

- `tmux`: 터미널 session/window/pane 관리
- `yazi`: 터미널 파일 탐색기
- `fzf`, `ripgrep`, `zoxide`, `jq`, `7zip`: 터미널 작업 보조 도구
- Tmux Plugin Manager
- tmux 플러그인: catppuccin theme, cpu, battery, resurrect, continuum
- Windows clipboard 연동: copy-mode에서 `clip.exe`로 복사

기존 `~/.tmux.conf`가 있으면 스크립트가 timestamp가 붙은 백업 파일을 만든 뒤 새 설정을 쓴다.

## 시작 명령

새 session을 만든다.

```bash
tmux new -s main
```

나중에 다시 붙는다.

```bash
tmux attach -t main
```

session 목록을 본다.

```bash
tmux ls
```

session을 종료한다.

```bash
tmux kill-session -t main
```

## Prefix

기본 prefix는 `Ctrl+Space`다. 기존 습관을 위해 `Ctrl+b`도 보조 prefix로 남겨둔다.

tmux 명령은 보통 prefix를 먼저 누르고 손을 뗀 다음, 다음 키를 누른다.

예: 새 window 만들기

```text
Ctrl+Space
c
```

## 자주 쓰는 키

| 키 | 기능 |
|---|---|
| `Prefix + c` | 새 window |
| `Prefix + n` | 다음 window |
| `Prefix + p` | 이전 window |
| `Prefix + 0..9` | 번호로 window 이동 |
| `Prefix + %` | 좌우 split |
| `Prefix + "` | 위아래 split |
| `Prefix + Tab` | 오른쪽 50% split에 yazi 열기 |
| `Prefix + r` | `~/.tmux.conf` 다시 읽기 |
| `Prefix + L` | 마지막 window |
| `Alt+h/j/k/l` | pane 이동 |

## Copy Mode

```text
Prefix + [
```

copy-mode 안에서:

| 키 | 기능 |
|---|---|
| `v` | 선택 시작 |
| `y` | Windows clipboard로 복사 |
| `Enter` | Windows clipboard로 복사 |
| `q` | copy-mode 종료 |

clipboard 연동 확인:

```bash
echo test | clip.exe
```

Windows 메모장에 붙여넣어 `test`가 나오면 정상이다.

## Yazi 기본

```bash
yazi
```

| 키 | 기능 |
|---|---|
| `h` / `l` | 상위 폴더 / 폴더 진입 |
| `j` / `k` | 아래 / 위 |
| `Enter` | 열기 |
| `Space` | 선택 |
| `y` | 복사 |
| `x` | 잘라내기 |
| `p` | 붙여넣기 |
| `q` | 종료 |

## 검증

Ubuntu/WSL에서 실행한다.

```bash
tmux -V
yazi --version
tmux display-message -p "Prefix: #{prefix}"
ls ~/.tmux/plugins/
```

예상 prefix:

```text
Prefix: C-Space
```

플러그인 폴더에는 아래 항목이 있어야 한다.

```text
catppuccin
tmux-battery
tmux-continuum
tmux-cpu
tmux-resurrect
tpm
```

## 오류 대응

| 증상 | 의미 | 대응 |
|---|---|---|
| `wsl: distro not found` | Ubuntu가 설치되지 않음 | `wsl --install Ubuntu` 후 재부팅 |
| `tmux: command not found` | tmux 설치 실패 | `bash scripts/setup-tmux-yazi.sh` 재실행 |
| `yazi: command not found` | yazi 설치 실패 또는 PATH 문제 | `which yazi` 확인 후 스크립트 재실행 |
| 복사가 Windows에 붙지 않음 | `clip.exe` 연동 문제 | `echo test \| clip.exe` 확인 |
| 색이 깨짐 | terminal/폰트/색상 문제 | Windows Terminal의 Ubuntu 탭에서 실행 |

## 교육자료

초보자와 중학생 대상 수업용 HTML은 아래 파일이다.

```text
docs/tmux-yazi-beginner-handout.html
```

브라우저로 열어서 읽거나, 하단 `PDF로 저장` 버튼으로 출력용 자료를 만들 수 있다.
