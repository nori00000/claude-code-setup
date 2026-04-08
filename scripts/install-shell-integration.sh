#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSHRC="${HOME}/.zshrc"
BLOCK_START="# >>> claude-code-setup >>>"
BLOCK_END="# <<< claude-code-setup <<<"

# Check for existing cc() function conflict
if [[ -f "${ZSHRC}" ]] && grep -qE 'cc\(\)' "${ZSHRC}" || grep -qF 'cc-function.sh' "${ZSHRC}" 2>/dev/null; then
  echo "WARNING: Existing cc() function detected in ~/.zshrc"
  echo "This script will NOT overwrite it. Using 'cl' prefix instead."
fi

read -r -d '' ZSH_BLOCK <<EOF || true
${BLOCK_START}
cl() {
  local prompt="작업은 최대한 자동으로 진행하되, 큰 파일 삭제나 다수 파일 삭제는 먼저 확인하고 진행해줘."
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
  if [[ \$# -gt 0 ]]; then
    claude --permission-mode auto "\$prompt"\$'\\n'"\$proposal"\$'\\n'"작업 지시: \$*"
  else
    claude --permission-mode auto "\$prompt"\$'\\n'"\$proposal"
  fi
}
clr() {
  local prompt="코드 변경은 하지 말고, 삭제 위험, 회귀 가능성, 누락 테스트만 리뷰해줘"
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
  local comment="\$*"
  local feedback_dir="\${HOME}/.claude/feedback"
  mkdir -p "\${feedback_dir}"
  local file="\${feedback_dir}/\$(date +%Y-%m).jsonl"
  printf '{"ts":"%s","satisfaction":%s,"helpfulness":"%s","clarity":"%s","comment":"%s"}\n' \\
    "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\${sat}" "\${help}" "\${clarity}" "\${comment}" >> "\${file}"
  echo "Feedback saved to \${file}"
}
cli() {
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
