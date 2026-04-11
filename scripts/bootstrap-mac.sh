#!/usr/bin/env bash
# =============================================================================
# bootstrap-mac.sh — Claude Code 개발환경 전체 셋업
#
# 새 Mac에서의 설치 순서:
#   1. brew install gh && gh auth login
#   2. git clone git@github.com:nori00000/claude-code-setup.git ~/claude-code-setup
#   3. bash ~/claude-code-setup/scripts/bootstrap-mac.sh
#
# 이미 셋업된 Mac에서는 이 스크립트를 다시 실행해서 재설치/업데이트 가능.
# =============================================================================
set -euo pipefail

# ── 색상 & 로그 ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[  OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*"; }
step()  { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMUX_SESSION="${TMUX_SESSION:-claude}"

# ── 0. 사전 요구사항 ─────────────────────────────────────────────────────────
step "0. 사전 요구사항 (Homebrew, Node.js, python3)"

if command -v brew &>/dev/null; then
  ok "Homebrew: $(brew --version 2>/dev/null | head -1)"
else
  info "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew 설치 완료"
fi

if command -v node &>/dev/null; then
  ok "Node.js: $(node --version)"
else
  info "Node.js 설치 중..."
  brew install node
  ok "Node.js: $(node --version)"
fi

command -v python3 >/dev/null 2>&1 || { fail "python3가 필요합니다"; exit 1; }
ok "python3: $(python3 --version)"

# ── 1. Claude Code ─────────────────────────────────────────────────────────
step "1. Claude Code 설치/업데이트"

if command -v claude &>/dev/null; then
  CURRENT=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo unknown)
  LATEST=$(npm show @anthropic-ai/claude-code version 2>/dev/null || echo unknown)
  info "현재: ${CURRENT} / 최신: ${LATEST}"
  if [[ "$CURRENT" == "$LATEST" ]]; then
    ok "이미 최신 (${CURRENT})"
  else
    info "업데이트 중..."
    npm update -g @anthropic-ai/claude-code
    ok "업데이트 완료"
  fi
else
  info "설치 중..."
  npm install -g @anthropic-ai/claude-code
  ok "설치 완료: $(claude --version 2>/dev/null | head -1)"
fi

# ── 2. OMC (oh-my-claudecode) ──────────────────────────────────────────────
step "2. OMC 설치/업데이트"

OMC_PKG="$HOME/.claude/plugins/marketplaces/oh-my-claudecode/package.json"
if [[ -f "$OMC_PKG" ]]; then
  CUR=$(python3 -c "import json; print(json.load(open('$OMC_PKG'))['version'])" 2>/dev/null || echo unknown)
  LAT=$(npm show oh-my-claudecode version 2>/dev/null || echo unknown)
  info "현재: ${CUR} / 최신: ${LAT}"
  if [[ "$CUR" == "$LAT" ]]; then
    ok "이미 최신 (${CUR})"
  else
    info "업데이트 시도..."
    claude plugins update oh-my-claudecode 2>/dev/null || warn "자동 업데이트 실패 — 수동: claude plugins install oh-my-claudecode"
  fi
else
  info "설치 시도..."
  claude plugins install oh-my-claudecode 2>/dev/null || warn "설치 실패 — 수동 설치 필요"
fi

# ── 3. tmux ────────────────────────────────────────────────────────────────
step "3. tmux 설치/업데이트"

if command -v tmux &>/dev/null; then
  ok "tmux: $(tmux -V)"
  if brew list tmux &>/dev/null && [[ -n "$(brew outdated tmux 2>/dev/null)" ]]; then
    info "업데이트 중..."
    brew upgrade tmux
  fi
else
  info "설치 중..."
  brew install tmux
  ok "설치 완료: $(tmux -V)"
fi

# ── 4. 파괴적 명령 차단 Hook (★ auto 모드 전에 반드시) ───────────────────────
step "4. 안전 hook 설치 (deny-destructive-commands)"

bash "${SCRIPT_DIR}/install-hooks.sh"

# ── 5. Shell integration (cl/clp/clr/clf/cli) ──────────────────────────────
step "5. Shell integration 설치 (cl/clp/clr/clf/cli)"

bash "${SCRIPT_DIR}/install-shell-integration.sh"

# ── 6. settings.json auto 퍼미션 (hook이 이미 설치됐으므로 안전) ─────────────
step "6. Claude Code auto 퍼미션 모드"

mkdir -p "$HOME/.claude"
SETTINGS_FILE="$HOME/.claude/settings.json"
python3 - "$SETTINGS_FILE" <<'PY'
import json, pathlib, sys

p = pathlib.Path(sys.argv[1])
d = json.loads(p.read_text()) if p.exists() else {}

d.setdefault('permissions', {})
d['permissions']['defaultMode'] = 'auto'

default_allow = [
    'Read', 'Write', 'Edit', 'Bash', 'Glob', 'Grep',
    'Agent', 'Skill', 'ToolSearch',
    'WebFetch', 'WebSearch',
    'mcp__filesystem__*', 'mcp__github__*', 'mcp__git__*', 'mcp__fetch__*'
]
existing = d['permissions'].get('allow', [])
d['permissions']['allow'] = list(dict.fromkeys(default_allow + existing))

p.write_text(json.dumps(d, indent=2, ensure_ascii=False))
print('settings.json 업데이트 완료')
PY
ok "auto 퍼미션 + 기본 allow 목록 설정됨 (deny hook이 위험 명령 차단)"

# ── 7. 로컬 alias (bootstrap-mac을 dev-setup으로 단축) ──────────────────────
step "7. dev-setup alias 등록"

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
if ! grep -q "alias dev-setup=" "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# claude-code-setup bootstrap alias"
    echo "alias dev-setup='bash ${REPO_ROOT}/scripts/bootstrap-mac.sh'"
  } >> "$ZSHRC"
  ok "'dev-setup' alias 추가됨"
else
  ok "'dev-setup' alias 이미 등록됨"
fi

# ── 8. tmux 세션 + Claude Code 실행 ─────────────────────────────────────────
step "8. tmux 세션 준비"

if [[ -n "${TMUX:-}" ]]; then
  info "이미 tmux 세션 안입니다. bootstrap 완료."
  exit 0
fi

if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  ok "기존 tmux 세션 '${TMUX_SESSION}' 있음"
  echo ""
  echo -e "  연결: ${CYAN}tmux attach -t ${TMUX_SESSION}${NC}"
else
  info "tmux 세션 '${TMUX_SESSION}' 생성"
  tmux new-session -d -s "$TMUX_SESSION"
  ok "생성 완료"
  echo ""
  echo -e "  연결: ${CYAN}tmux attach -t ${TMUX_SESSION}${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}============================================${NC}"
echo -e "${GREEN}${BOLD}  bootstrap-mac 완료!${NC}"
echo -e "${GREEN}${BOLD}============================================${NC}"
echo ""
echo -e "  ${CYAN}사용법:${NC}"
echo -e "    ${YELLOW}source ~/.zshrc${NC}       # 또는 새 터미널 열기"
echo -e "    ${YELLOW}cl \"작업\"${NC}              # Claude Code 실행 (tmux 자동 래핑)"
echo -e "    ${YELLOW}dev-setup${NC}              # 다음에 재셋업 시 한 단어"
echo ""
