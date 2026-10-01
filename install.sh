#!/usr/bin/env bash
# Install this repo's Claude Code config into ~/.claude on the current machine,
# and its markdownlint rules into ~/.markdownlint.yaml.
#
#   ./install.sh            symlink (falls back to copying if the OS refuses)
#   ./install.sh --copy     always copy
#   ./install.sh --dry-run  show what would happen, change nothing
#   ./install.sh --replace-existing  replace files that differ without asking
#
# Where a file already differs from the repo's, it asks whether to keep it,
# replace it, or show the difference. With no terminal to ask on, it keeps it.
# A replaced file moves to ~/.claude/backups/<name>.<timestamp>.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"
stamp="$(date +%Y%m%d-%H%M%S)"
mode=link
dry=0
replace_existing=0
fell_back=0
kept=0
kept_settings=0

# Parsed with a shift loop rather than `for arg in "$@"`: bash 3.2 -- still the
# system bash on macOS -- treats an empty "$@" as unbound under `set -u`.
while [ $# -gt 0 ]; do
  case "$1" in
    --copy)    mode=copy ;;
    --dry-run) dry=1 ;;
    --replace-existing) replace_existing=1 ;;
    -h|--help) awk 'NR == 1 { next } /^#/ { print; next } { exit }' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)         echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '%s\n' "$*"; }
run() { if [ "$dry" -eq 1 ]; then say "  would: $*"; else "$@"; fi; }

# Move anything already at the destination out of the way. A link that points
# somewhere else moves too, since it may be another setup's.
#
# Backups collect in one directory instead of sitting beside the original.
# Claude Code loads every directory under ~/.claude/skills/ as a skill, so a
# backup left next to a skill is not inert: it registers as a second, stale copy
# of that skill, and reinstalling adds another one every time.
backup() {
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  local saved="$dest/backups/$(basename "$target").$stamp"
  say "  backing up existing $target -> $saved"
  run mkdir -p "$dest/backups"
  run mv "$target" "$saved"
  [ "$dry" -eq 1 ] || say "  to restore it: mv '$saved' '$target'"
}

# Decide what to do with a target that differs from src. Returns 0 to replace
# it, 1 to keep it. A replace nobody chose would lose someone's work, so keep
# is the default everywhere a person cannot answer.
replace_ok() {
  local src="$1" target="$2" answer
  [ "$replace_existing" -eq 1 ] && return 0
  if [ "$dry" -eq 1 ]; then
    say "  would ask before replacing $target"
    return 1
  fi
  if [ ! -t 0 ]; then
    keep "$target" "differs from the repo; --replace-existing replaces it"
    return 1
  fi
  if [ -L "$target" ]; then
    say "  $target is a link to $(readlink "$target")"
  else
    say "  $target differs from $src"
  fi
  while :; do
    printf '  [k]eep it, [r]eplace it, [d]iff, or [q]uit? (k) '
    read -r answer || answer=k
    case "$answer" in
      ""|k|K) keep "$target" "your choice"; return 1 ;;
      r|R)    return 0 ;;
      # diff exits 1 when the two differ, which here is the expected case.
      d|D)    diff -ru "$target" "$src" || true ;;
      q|Q)    say "stopped; nothing after $target was changed."; exit 1 ;;
    esac
  done
}

keep() {
  say "  kept $1: $2"
  kept=1
  [ "$1" = "$dest/settings.json" ] && kept_settings=1
  return 0
}

# True when target is a link to src, as a previous run leaves it.
linked() { [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; }

# True when target is a plain file or directory holding what src holds.
same_copy() {
  [ -L "$2" ] && return 1
  if [ -d "$1" ]; then
    [ -d "$2" ] && diff -rq "$1" "$2" >/dev/null 2>&1
  else
    [ -f "$2" ] && cmp -s "$1" "$2"
  fi
}

# Symlinks need Developer Mode or admin on Windows. Try, verify, fall back.
place() {
  local src="$1" target="$2"
  if { [ "$mode" = link ] && linked "$src" "$target"; } ||
    { [ "$mode" = copy ] && same_copy "$src" "$target"; }; then
    say "  unchanged $target"
    return 0
  fi
  # A link or copy of this repo's file holds nothing a backup would save.
  if linked "$src" "$target" || same_copy "$src" "$target"; then
    run rm -rf "$target"
  elif [ -e "$target" ] || [ -L "$target" ]; then
    replace_ok "$src" "$target" || return 0
    backup "$target"
  fi
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
place "$repo/claude/skills/repo-template-check" "$dest/skills/repo-template-check"
place "$repo/claude/skills/memory-audit" "$dest/skills/memory-audit"

# The markdownlint extension falls back to this file in a repo without its own
# config; markdownlint.configFile in VS Code's settings points at it.
place "$repo/.markdownlint.yaml"        "$HOME/.markdownlint.yaml"

# Git does not clone .git/hooks/, so the gates in .pre-commit-config.yaml are
# inert until something writes the hook into this clone. This is that step, and
# it touches only this repo -- no global core.hooksPath, which would override
# the hooks of every other repo on the machine.
#
# CLAUDE_HOME set means an install somewhere other than this machine's
# ~/.claude, such as the tests' scratch home, so this clone is left alone.
gates=on
say
if [ -n "${CLAUDE_HOME:-}" ]; then
  say "  skipping pre-commit install: CLAUDE_HOME is set"
elif [ "$dry" -eq 1 ]; then
  say "  would: pre-commit install"
elif command -v pre-commit >/dev/null 2>&1; then
  (cd "$repo" && pre-commit install)
else
  gates=off
fi

say
say "done. Restart Claude Code (or open /hooks once) so it reloads settings."

if [ "$kept" -eq 1 ]; then
  say
  say "Note: files marked \"kept\" above differ from the repo and were left alone."
  say "  Run ./install.sh in a terminal to choose for each, or add --replace-existing."
fi
# The hooks live in settings.json, so keeping someone's own file means going
# without them. A JSON merge here would need a parser this script avoids.
if [ "$kept_settings" -eq 1 ]; then
  say "  Your settings.json was kept, so this repo's hooks are not active."
  say "  To use them, copy the \"hooks\" block from $repo/claude/settings.json into it."
fi

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
