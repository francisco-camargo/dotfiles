#!/usr/bin/env bash
# Install this repo's Claude Code config into ~/.claude on the current machine.
#
#   ./install.sh            symlink (falls back to copying if the OS refuses)
#   ./install.sh --copy     always copy
#   ./install.sh --dry-run  show what would happen, change nothing
#
# Existing files move to ~/.claude/backups/<name>.<timestamp> before being replaced.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"
stamp="$(date +%Y%m%d-%H%M%S)"
mode=link
dry=0
fell_back=0

# Parsed with a shift loop rather than `for arg in "$@"`: bash 3.2 -- still the
# system bash on macOS -- treats an empty "$@" as unbound under `set -u`.
while [ $# -gt 0 ]; do
  case "$1" in
    --copy)    mode=copy ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)         echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '%s\n' "$*"; }
run() { if [ "$dry" -eq 1 ]; then say "  would: $*"; else "$@"; fi; }

# Move anything already at the destination out of the way. A symlink we placed
# on a previous run is just removed -- backing up a link is noise.
#
# Backups collect in one directory instead of sitting beside the original.
# Claude Code loads every directory under ~/.claude/skills/ as a skill, so a
# backup left next to a skill is not inert: it registers as a second, stale copy
# of that skill, and reinstalling adds another one every time.
backup() {
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  if [ -L "$target" ]; then
    run rm -f "$target"
    return 0
  fi
  local saved="$dest/backups/$(basename "$target").$stamp"
  say "  backing up existing $target -> $saved"
  run mkdir -p "$dest/backups"
  run mv "$target" "$saved"
}

# Symlinks need Developer Mode or admin on Windows. Try, verify, fall back.
place() {
  local src="$1" target="$2"
  backup "$target"
  run mkdir -p "$(dirname "$target")"
  if [ "$mode" = link ]; then
    if [ "$dry" -eq 1 ]; then
      say "  would: link $target -> $src"
      return 0
    fi
    # Git Bash needs MSYS=winsymlinks:nativestrict or `ln -s` copies the file
    # and exits 0, so the destination is a regular file and Developer Mode makes
    # no difference. nativestrict makes it attempt a real symlink and fail when
    # the OS refuses, which is what the -L check and the fallback below expect.
    # The variable means nothing to ln on macOS or Linux.
    if MSYS=winsymlinks:nativestrict ln -s "$src" "$target" 2>/dev/null && [ -L "$target" ]; then
      say "  linked $target"
      return 0
    fi
    rm -rf "$target"
    fell_back=1
    say "  (symlink unavailable -- copying instead)"
  fi
  run cp -r "$src" "$target"
  say "  copied $target"
}

say "installing from $repo into $dest"
[ "$dry" -eq 1 ] && say "(dry run -- nothing will change)"

place "$repo/claude/settings.json"      "$dest/settings.json"
place "$repo/claude/CLAUDE.md"          "$dest/CLAUDE.md"
place "$repo/claude/skills/md-to-pdf"   "$dest/skills/md-to-pdf"

# Git does not clone .git/hooks/, so the gates in .pre-commit-config.yaml are
# inert until something writes the hook into this clone. This is that step, and
# it touches only this repo -- no global core.hooksPath, which would override
# the hooks of every other repo on the machine.
gates=on
say
if [ "$dry" -eq 1 ]; then
  say "  would: pre-commit install"
elif command -v pre-commit >/dev/null 2>&1; then
  (cd "$repo" && pre-commit install)
else
  gates=off
fi

say
say "done. Restart Claude Code (or open /hooks once) so it reloads settings."

# Windows refuses symlinks to an ordinary user until Developer Mode is on, which
# is the state every new machine is in. Naming the fix here beats leaving someone
# to work out why "copying instead" appeared and what it costs them.
if [ "$fell_back" -eq 1 ]; then
  say
  say "Note: links were refused, so these are copies -- edits here will NOT reach $dest."
  say "  Turn on Developer Mode (Settings -> For developers), then re-run this script."
  say "  Until then, re-run it after every edit, and edit only in the repo."
fi

# Deliberately the last thing printed, and deliberately not a quiet line in the
# middle of the install. A gate nobody knows is off is the failure mode the
# README names: the layer misses "anyone who never enabled it". Installing a
# global Python tool as a side effect of placing config files would be the
# wrong fix -- saying so where it cannot be missed is the right one.
if [ "$gates" = off ]; then
  say
  say "!! This repo's commit gates are NOT active -- pre-commit is not installed."
  say "!! Nothing here will stop a credential being committed."
  say "!!"
  say "!! Install it however you install Python tools, then turn the gates on:"
  say "!!   uv tool install pre-commit && pre-commit install"
  say "!!   pipx install pre-commit && pre-commit install"
  say "!!"
  say "!! The first run downloads roughly 340 MB into ~/.cache/pre-commit,"
  say "!! most of it the Go toolchain that gitleaks needs."
fi
