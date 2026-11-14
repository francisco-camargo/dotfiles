#!/usr/bin/env bash
# Feed sample commands to each PreToolUse gate in claude/settings.json and
# check whether it denies, asks, or allows them.
#
#   tests/hooks-test.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
settings="${1:-$repo/claude/settings.json}"
failed=0

# Pull a gate's command back out of settings.json and undo the JSON escaping,
# so the test runs the string the hook runs, not one retyped by hand.
# Claude Code then turns each \\ into \ once more before the shell sees it,
# so do that too.
gate() {
  grep -F "$1" "$settings" | grep -F '"command":' |
    sed -e 's/^[[:space:]]*"command":[[:space:]]*"//' -e 's/",[[:space:]]*$//' \
      -e 's/\\\(.\)/\1/g' |
    sed -e 's/\\\\/\\/g'
}

git_gate="$(gate 'git commit/push needs')"
sed_gate="$(gate 'No editing with sed')"
py_gate="$(gate 'Run Python through uv')"

# The sed and uv gates each have a Bash and a PowerShell handler, since an
# `if` rule names one tool. Their commands must stay identical.
for g in git_gate sed_gate py_gate; do
  [[ -n "${!g}" ]] || { printf 'FAIL  could not find %s in settings.json\n' "$g"; exit 1; }
  if [[ "$(printf '%s\n' "${!g}" | sort -u | wc -l)" -ne 1 ]]; then
    printf 'FAIL  copies of %s differ\n' "$g"
    exit 1
  fi
  printf -v "$g" '%s' "$(printf '%s\n' "${!g}" | head -n 1)"
done

# Wrap a command in a payload shaped like the one Claude Code sends.
payload() {
  local c="$1"
  c="${c//\\/\\\\}"
  c="${c//\"/\\\"}"
  c="${c//$'\n'/\\n}"
  printf '{"session_id":"t","tool_name":"Bash","tool_input":{"command":"%s","description":"%s"}}' \
    "$c" "${2:-Read the files, then the functions}"
}

decision() {
  local out
  out="$(payload "$2" | bash -c "$1")"
  case "$out" in
    *'"deny"'*) echo deny ;;
    *'"ask"'*) echo ask ;;
    *) echo allow ;;
  esac
}

expect() {
  local want="$1" name="$2" hook="$3" cmd="$4" got
  got="$(decision "$hook" "$cmd")"
  if [[ "$got" == "$want" ]]; then
    printf 'ok    %s\n' "$name"
  else
    printf 'FAIL  %s: want %s, got %s\n' "$name" "$want" "$got"
    failed=1
  fi
}

expect ask   'git commit'                 "$git_gate" 'git commit -m x'
expect ask   'git push on a later line'   "$git_gate" $'cd repo\ngit push'
expect allow 'git status'                 "$git_gate" 'git status'

expect deny  'sed -i'                     "$sed_gate" "sed -i 's/a/b/' f"
expect deny  'sed -i after &&'            "$sed_gate" "cd x && sed -i 's/a/b/' f"
expect deny  'sed -i on a later line'     "$sed_gate" $'f=x\nsed -i -e \'s/a/b/\' f'
expect allow 'sed -n'                     "$sed_gate" "sed -n '1,5p' f"
expect allow 'sed -n, description has s,' "$sed_gate" 'sed -n 1p f'
expect allow 'sed -i in a commit -m'      "$sed_gate" 'git commit -m "Deny sed -i edits"'
expect allow 'sed -i in a commit heredoc' "$sed_gate" $'git commit -F - <<\'EOF\'\nGate edits\n\nsed -i now fails.\nEOF'
expect deny  'sed -i before a commit'     "$sed_gate" "sed -i 's/a/b/' f && git commit -m x"

expect deny  'python'                     "$py_gate"  'python x.py'
expect deny  'python3 after ;'            "$py_gate"  'cd x; python3 x.py'
expect deny  'python on a later line'     "$py_gate"  $'cd x\npython x.py'
expect allow 'uv run python'              "$py_gate"  'uv run python x.py'
expect allow 'python in a commit heredoc' "$py_gate"  $'git commit -F - <<\'EOF\'\nUse uv\n\npython x.py fails here.\nEOF'
expect allow 'venv interpreter'           "$py_gate"  '.venv/Scripts/python.exe x.py'

exit "$failed"
