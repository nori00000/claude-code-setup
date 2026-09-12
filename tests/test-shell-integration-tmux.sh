#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin" "$test_root/fallback-bin" "$test_root/home" "$test_root/one/api" "$test_root/two/api" "$test_root/three/api" "$test_root/matching/api" "$test_root/legacy-owner/api" "$test_root/unique" "$test_root/fallback"
ln -s "$test_root/one/api" "$test_root/symlink-api"

cp "$repo_root/tests/fixtures/mock-tmux" "$test_root/bin/tmux"
cp "$repo_root/tests/fixtures/failing-shasum" "$test_root/fallback-bin/shasum"
cp "$repo_root/tests/fixtures/fixed-cksum" "$test_root/fallback-bin/cksum"
chmod +x "$test_root/bin/tmux"
chmod +x "$test_root/fallback-bin/shasum" "$test_root/fallback-bin/cksum"

HOME="$test_root/home" "$repo_root/scripts/install-shell-integration.sh" >/dev/null

run_cl() {
  local dir="$1"
  local command_path="${2:-$test_root/bin:$PATH}"
  PATH="$command_path" TMUX_STATE="$test_root/state" TMUX_LOG="$test_root/tmux.log" \
    zsh -fc "source '$test_root/home/.zshrc'; cd '$dir'; cl test"
}

new_legacy() {
  local dir="$1"
  PATH="$test_root/bin:$PATH" TMUX_STATE="$test_root/state" TMUX_LOG="$test_root/tmux.log" \
    tmux new-session -d -s cl-api -c "$dir"
}

mkdir "$test_root/state"
run_cl "$test_root/one/api"
run_cl "$test_root/two/api"
run_cl "$test_root/unique"
run_cl "$test_root/unique"
run_cl "$test_root/symlink-api"

# A matching legacy session remains reachable after upgrading.
new_legacy "$test_root/matching/api"
run_cl "$test_root/matching/api"

# A legacy session belonging to another same-basename directory must not win.
new_legacy "$test_root/legacy-owner/api"
run_cl "$test_root/three/api"

# If shasum cannot produce a hash, cksum still creates a stable session name.
run_cl "$test_root/fallback" "$test_root/fallback-bin:$test_root/bin:$PATH"

created=()
while IFS= read -r session; do
  created+=("$session")
done < <(awk '$1 == "new-session" { print $4 }' "$test_root/tmux.log")
[[ "${#created[@]}" -eq 7 ]] || { echo "expected seven new sessions, got ${#created[@]}" >&2; exit 1; }
[[ "${created[0]}" != "${created[1]}" ]] || { echo "same-basename paths collided" >&2; exit 1; }
[[ "${created[2]}" == cl-unique-* ]] || { echo "readable basename missing: ${created[2]}" >&2; exit 1; }
[[ "${created[3]}" == "cl-api" ]] || { echo "matching legacy session was not created" >&2; exit 1; }
[[ "${created[5]}" == cl-api-* ]] || { echo "mismatched legacy session was reused" >&2; exit 1; }
[[ "${created[6]}" == "cl-fallback-4242" ]] || { echo "cksum fallback was not used" >&2; exit 1; }

attach_count="$(awk '$1 == "attach-session" { count++ } END { print count + 0 }' "$test_root/tmux.log")"
[[ "$attach_count" -eq 8 ]] || { echo "expected all cl calls to attach" >&2; exit 1; }
awk '$1 == "attach-session" && $3 == "cl-api" { found = 1 } END { exit !found }' "$test_root/tmux.log" || { echo "matching legacy session was not attached" >&2; exit 1; }

echo "tmux shell integration tests passed"
