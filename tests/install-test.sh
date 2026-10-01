#!/usr/bin/env bash
# Run install.sh against a scratch home and check that it never replaces
# something it did not put there unless asked to.
#
#   tests/install-test.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home"
failed=0

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'ok    %s\n' "$name"
  else
    printf 'FAIL  %s\n' "$name"
    failed=1
  fi
}

fresh_home() { rm -rf "$home"; mkdir -p "$home/.claude"; }

# stdin from /dev/null stands in for a run with no terminal to ask on.
install() {
  HOME="$home" CLAUDE_HOME="$home/.claude" "$repo/install.sh" --copy "$@" \
    </dev/null >"$tmp/out" 2>&1
}

no_backups() { [ ! -e "$home/.claude/backups" ]; }
has_backup() { ls "$home/.claude/backups/CLAUDE.md."* >/dev/null 2>&1; }
holds() { [ "$(cat "$1")" = "$2" ]; }
same_as_repo() { cmp -s "$repo/claude/CLAUDE.md" "$home/.claude/CLAUDE.md"; }

help_ends_with_backups() { "$repo/install.sh" --help | tail -n 1 | grep -q backups; }
check "--help prints the whole header" help_ends_with_backups

fresh_home
install
check "an empty home gets every file" same_as_repo
check "an empty home gets the markdownlint rules" \
  cmp -s "$repo/.markdownlint.yaml" "$home/.markdownlint.yaml"
check "an empty home gets the spelling words" \
  cmp -s "$repo/vscode/cspell-words.txt" "$home/.cspell-words.txt"

install
check "a second run backs nothing up" no_backups

fresh_home
echo "my own instructions" >"$home/.claude/CLAUDE.md"
install || true
check "with no terminal, a file that differs is kept" \
  holds "$home/.claude/CLAUDE.md" "my own instructions"
check "  ...and the run says so" grep -q "kept" "$tmp/out"

fresh_home
echo "my own instructions" >"$home/.claude/CLAUDE.md"
install --replace-existing || true
check "--replace-existing replaces a file that differs" same_as_repo
check "  ...after backing it up" has_backup

fresh_home
echo "someone else's" >"$tmp/elsewhere"
if MSYS=winsymlinks:nativestrict ln -s "$tmp/elsewhere" "$home/.claude/CLAUDE.md" 2>/dev/null &&
  [ -L "$home/.claude/CLAUDE.md" ]; then
  install || true
  check "a link that points outside this repo is kept" \
    holds "$home/.claude/CLAUDE.md" "someone else's"
else
  printf 'skip  a link that points outside this repo is kept (no symlinks here)\n'
fi

templatedir() { HOME="$home" git config --global --get init.templateDir; }

fresh_home
install
check "new clones get the pre-commit hook" \
  [ -f "$home/.git-template/hooks/pre-commit" ]
check "  ...through init.templateDir" [ "$(templatedir)" = "~/.git-template" ]

fresh_home
# A ~ path, since Git Bash would rewrite a leading / into a Windows path.
HOME="$home" git config --global init.templateDir "~/my-template"
install || true
check "an init.templateDir set elsewhere is kept" [ "$(templatedir)" = "~/my-template" ]
check "  ...and the run says so" grep -q "init.templateDir" "$tmp/out"

exit "$failed"
