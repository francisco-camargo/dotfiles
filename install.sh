#!/usr/bin/env bash
# Install this repo's Claude Code config into ~/.claude on the current machine.
#
#   ./install.sh            symlink (falls back to copying if the OS refuses)
#   ./install.sh --copy     always copy
#   ./install.sh --dry-run  show what would happen, change nothing
#
# Existing files are backed up to <name>.bak.<timestamp> before being replaced.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"
stamp="$(date +%Y%m%d-%H%M%S)"
mode=link
dry=0

for arg in "$@"; do
  case "$arg" in
    --copy)    mode=copy ;;
    --dry-run) dry=1 ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)         echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }
run() { if [ "$dry" -eq 1 ]; then say "  would: $*"; else "$@"; fi; }

# Move anything already at the destination out of the way. A symlink we placed
# on a previous run is just removed -- backing up a link is noise.
backup() {
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  if [ -L "$target" ]; then
    run rm -f "$target"
  else
    say "  backing up existing $target -> $target.bak.$stamp"
    run mv "$target" "$target.bak.$stamp"
  fi
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
    if ln -s "$src" "$target" 2>/dev/null && [ -L "$target" ]; then
      say "  linked $target"
      return 0
    fi
    rm -rf "$target"
    say "  (symlink unavailable -- copying instead)"
  fi
  run cp -r "$src" "$target"
  say "  copied $target"
}

say "installing from $repo into $dest"
[ "$dry" -eq 1 ] && say "(dry run -- nothing will change)"

place "$repo/claude/settings.json"      "$dest/settings.json"
place "$repo/claude/skills/md-to-pdf"   "$dest/skills/md-to-pdf"

say
say "done. Restart Claude Code (or open /hooks once) so it reloads settings."
