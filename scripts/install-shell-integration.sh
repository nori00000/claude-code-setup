#!/usr/bin/env bash
set -euo pipefail

# Require python3 for install/update
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required"; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSHRC="${HOME}/.zshrc"
BLOCK_START="# >>> claude-code-setup >>>"
BLOCK_END="# <<< claude-code-setup <<<"

# Check for existing cc() function conflict (M6: grouped greps)
if [[ -f "${ZSHRC}" ]] && { grep -qE 'cc\(\)' "${ZSHRC}" || grep -qF 'cc-function.sh' "${ZSHRC}" 2>/dev/null; }; then
  echo "WARNING: Existing cc() function detected in ~/.zshrc"
  echo "This script will NOT overwrite it. Using 'cl' prefix instead."
fi

read -r -d '' ZSH_BLOCK <<EOF || true
${BLOCK_START}
_cl_tmux_wrap() {
  # If CL_NO_TMUX is set, or already inside tmux, run inline
  if [[ -n "\${CL_NO_TMUX:-}" ]] || [[ -n "\${TMUX:-}" ]]; then
    return 1
  fi
  if ! command -v tmux >/dev/null 2>&1; then
    return 1
  fi
  # Sanitize session name (tmux disallows . : in names)
  local sess="cl-\$(basename "\$PWD" | tr './:' '-')"
  # -A: attach if exists, create if not. Run cl inside with CL_NO_TMUX=1 to prevent recursion.
  if tmux has-session -t "\$sess" 2>/dev/null; then
    tmux attach-session -t "\$sess"
  else
    tmux new-session -s "\$sess" -c "\$PWD" "CL_NO_TMUX=1 \$SHELL"
  fi
  return 0
}
_cl_update_profile() {
  local profile="\$PWD/.claude/project-profile.md"
  [[ -f "\$profile" && -w "\$profile" ]] || return 0
  local machine="\$(hostname -s 2>/dev/null || echo unknown)"
  local now="\$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  command -v python3 >/dev/null 2>&1 || return 0
  python3 -c "
import pathlib, re, sys
try:
    p = pathlib.Path(sys.argv[1])
    t = p.read_text()
    m, n = sys.argv[2], sys.argv[3]
    t = re.sub(r'last_machine:.*', lambda _: f\"last_machine: '{m}'\", t)
    t = re.sub(r'last_session:.*', lambda _: f\"last_session: '{n}'\", t)
    p.write_text(t)
except Exception:
    pass
" "\$profile" "\$machine" "\$now"
}
_cl_show_handoff() {
  local current="\$(hostname -s 2>/dev/null || echo unknown)"
  local project="\$(basename "\$PWD")"
  local shown=false

  # Source 1: dev-retrospective last_session.json (single python3 call per machine)
  local machines_dir="\$HOME/.dev-retrospective/data/machines"
  if [[ -d "\$machines_dir" ]] && command -v python3 >/dev/null 2>&1; then
    for mdir in "\$machines_dir"/*/; do
      local mname="\$(basename "\$mdir")"
      [[ "\$mname" == "\$current" ]] && continue
      local sess="\$mdir/last_session.json"
      [[ -f "\$sess" ]] || continue
      # Single python3 call for all fields
      local info
      info="\$(python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(d.get('project',''))
    print(d.get('timestamp',''))
    print(d.get('git_branch',''))
    print(d.get('dirty_files',0))
    print(d.get('unpushed_commits',0))
except Exception:
    print('')
" "\$sess" 2>/dev/null)"
      local m_project m_ts m_branch m_dirty m_unpushed
      { IFS= read -r m_project; IFS= read -r m_ts; IFS= read -r m_branch; IFS= read -r m_dirty; IFS= read -r m_unpushed; } <<< "\$info"
      if [[ "\$m_project" == "\$project" ]]; then
        echo "\\033[33m[handoff]\\033[0m \$mname → \$project (\$m_ts, branch: \$m_branch)"
        [[ "\${m_dirty:-0}" -gt 0 ]] 2>/dev/null && echo "  ⚠ dirty: \${m_dirty}파일"
        [[ "\${m_unpushed:-0}" -gt 0 ]] 2>/dev/null && echo "  ⚠ unpushed: \${m_unpushed}커밋"
        shown=true
      fi
    done
  fi

  # Source 2: project-profile.md fallback
  if [[ "\$shown" == false ]]; then
    local profile="\$PWD/.claude/project-profile.md"
    if [[ -f "\$profile" ]]; then
      local last_m last_s
      last_m="\$(grep 'last_machine:' "\$profile" 2>/dev/null | head -1 | sed "s/.*: *'\\{0,1\\}//;s/'.*$//")"
      last_s="\$(grep 'last_session:' "\$profile" 2>/dev/null | head -1 | sed "s/.*: *'\\{0,1\\}//;s/'.*$//")"
      if [[ -n "\$last_m" && "\$last_m" != "\$current" && "\$last_m" != "" ]]; then
        echo "\\033[33m[handoff]\\033[0m 이전 머신: \$last_m (\$last_s)"
      fi
    fi
  fi
}
cl() {
  local prompt="작업은 최대한 자동으로 진행하되, 큰 파일 삭제나 다수 파일 삭제는 먼저 확인하고 진행해줘."
  if _cl_tmux_wrap; then return; fi
  _cl_show_handoff
  _cl_update_profile
  if [[ \$# -gt 0 ]]; then
    claude --permission-mode auto "\$prompt"\$'\\n'"작업 지시: \$*"
  else
    claude --permission-mode auto "\$prompt"
  fi
}
clp() {
  local prompt="작업은 최대한 자동으로 진행하되, 큰 파일 삭제나 다수 파일 삭제는 먼저 확인하고 진행해줘."
  local proposal='먼저 바로 구현하지 말고 아래 형식으로만 짧게 제안해줘.
1. 현재 이해 - 내가 이해한 목표, 영향 범위
2. 선택지 - 1안: 최소 변경안, 2안: 기본 추천안, 3안: 확장안
3. 쉬운 설명 - 각 안이 실제로 무엇을 의미하는지
4. 장단점 - 각 안의 얻는 점과 비용 또는 위험
5. 추천 - 딱 1개의 추천안과 이유
6. 짧게 답할 것 - 질문은 최대 3개, 1/2/3처럼 짧게 고를 수 있게
내가 고르면 그다음 구현으로 넘어가줘.'
  if _cl_tmux_wrap; then return; fi
  _cl_show_handoff
  _cl_update_profile
  if [[ \$# -gt 0 ]]; then
    claude --permission-mode auto "\$prompt"\$'\\n'"\$proposal"\$'\\n'"작업 지시: \$*"
  else
    claude --permission-mode auto "\$prompt"\$'\\n'"\$proposal"
  fi
}
clr() {
  local prompt="코드 변경은 하지 말고, 삭제 위험, 회귀 가능성, 누락 테스트만 리뷰해줘"
  if _cl_tmux_wrap; then return; fi
  _cl_show_handoff
  _cl_update_profile
  if [[ \$# -gt 0 ]]; then
    claude --permission-mode auto "\$prompt"\$'\\n'"추가 지시: \$*"
  else
    claude --permission-mode auto "\$prompt"
  fi
}
clf() {
  if [[ \$# -lt 3 ]]; then
    echo "usage: clf <satisfaction:1-5> <helpful|neutral|not_helpful> <clear|mixed|unclear> [comment...]"
    return 2
  fi
  local sat="\$1" help="\$2" clarity="\$3"; shift 3
  # Input validation
  if [[ ! "\$sat" =~ ^[1-5]\$ ]]; then
    echo "Error: satisfaction must be 1-5 (got: \$sat)" >&2; return 2
  fi
  case "\$help" in helpful|neutral|not_helpful) ;; *)
    echo "Error: helpfulness must be helpful|neutral|not_helpful (got: \$help)" >&2; return 2 ;; esac
  case "\$clarity" in clear|mixed|unclear) ;; *)
    echo "Error: clarity must be clear|mixed|unclear (got: \$clarity)" >&2; return 2 ;; esac
  local comment="\$*"
  local feedback_dir="\${HOME}/.claude/feedback"
  mkdir -p "\${feedback_dir}"
  local file="\${feedback_dir}/\$(date +%Y-%m).jsonl"
  python3 -c "
import json, sys
print(json.dumps({'ts':sys.argv[1],'satisfaction':int(sys.argv[2]),'helpfulness':sys.argv[3],'clarity':sys.argv[4],'comment':sys.argv[5]}))
" "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\${sat}" "\${help}" "\${clarity}" "\${comment}" >> "\${file}"
  echo "Feedback saved to \${file}"
}
cli() {
  if _cl_tmux_wrap; then return; fi
  claude "\$@"
}
${BLOCK_END}
EOF

if [[ -f "${ZSHRC}" ]] && grep -Fq "${BLOCK_START}" "${ZSHRC}"; then
  python3 - "${ZSHRC}" "${BLOCK_START}" "${BLOCK_END}" "${ZSH_BLOCK}" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
start = sys.argv[2]
end = sys.argv[3]
replacement = sys.argv[4]
text = path.read_text()
pattern = re.compile(rf"{re.escape(start)}.*?{re.escape(end)}", re.S)
path.write_text(pattern.sub(replacement, text, count=1))
PY
  echo "Updated existing claude-code-setup block in ${ZSHRC}"
else
  printf '\n%s\n' "${ZSH_BLOCK}" >> "${ZSHRC}"
  echo "Appended claude-code-setup block to ${ZSHRC}"
fi

echo "Shell integration installed: cl, clp, clr, clf, cli"
echo "Open a new shell or run: source ~/.zshrc"
