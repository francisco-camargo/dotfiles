#!/usr/bin/env bash
# Print the Claude Code memory files kept for a project.
#
#   find.sh [project-dir]   the project's memory (default: current directory)
#   find.sh --all           every project that has memory files
#
# Prints each memory file in full, then index entries with no file and files
# with no index entry. Changes nothing.
set -euo pipefail

projects="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"
project="."
all=0

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     all=1; shift ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*)        echo "unknown option: $1" >&2; exit 2 ;;
    *)         project="$1"; shift ;;
  esac
done

[ -d "$projects" ] || { echo "no projects directory: $projects" >&2; exit 1; }

# Claude Code names a project's directory after its path, with every character
# other than a letter or digit turned into "-". On Windows the path is the
# native one, whose drive letter case varies, so keys compare in lower case.
key() {
  local path="$1"
  if command -v cygpath >/dev/null 2>&1; then path="$(cygpath -m "$path")"; fi
  printf '%s' "$path" | tr -c 'A-Za-z0-9' '-' | tr 'A-Z' 'a-z'
}

report() {
  local dir="$1/memory" f name
  echo "== $(basename "$1")"
  echo "   $dir"
  local files
  files="$(find "$dir" -maxdepth 1 -type f -name '*.md' ! -name MEMORY.md 2>/dev/null | sort)"
  if [ -z "$files" ] && [ ! -s "$dir/MEMORY.md" ]; then
    echo "   (no memories)"
    echo
    return
  fi
  if [ -f "$dir/MEMORY.md" ]; then
    echo
    echo "--- MEMORY.md"
    cat "$dir/MEMORY.md"
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    echo
    echo "--- $(basename "$f")"
    cat "$f"
  done <<< "$files"

  echo
  echo "--- index check"
  local problems=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    name="$(basename "$f")"
    if ! grep -qF "($name)" "$dir/MEMORY.md" 2>/dev/null; then
      echo "   not in MEMORY.md: $name"
      problems=1
    fi
  done <<< "$files"
  if [ -f "$dir/MEMORY.md" ]; then
    while IFS= read -r name; do
      if [ ! -f "$dir/$name" ]; then
        echo "   indexed but missing: $name"
        problems=1
      fi
    done < <(grep -o '([^)]*\.md)' "$dir/MEMORY.md" | tr -d '()')
  fi
  [ "$problems" -eq 1 ] || echo "   index matches files"
  echo
}

if [ "$all" -eq 1 ]; then
  found=0
  for d in "$projects"/*/; do
    d="${d%/}"
    if [ -n "$(find "$d/memory" -maxdepth 1 -type f -name '*.md' 2>/dev/null)" ]; then
      report "$d"
      found=1
    fi
  done
  [ "$found" -eq 1 ] || echo "no project has memory files"
  exit 0
fi

[ -d "$project" ] || { echo "no such directory: $project" >&2; exit 1; }
project="$(cd "$project" && pwd)"

# A session keys its memory by where it started: the directory itself, the
# top of its git work tree, or the main repo a worktree belongs to. Try each.
candidates="$project"
if top="$(git -C "$project" rev-parse --show-toplevel 2>/dev/null)"; then
  candidates="$candidates"$'\n'"$top"
  common="$(git -C "$project" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  [ -z "$common" ] || candidates="$candidates"$'\n'"$(dirname "$common")"
fi

matched=""
while IFS= read -r path; do
  k="$(key "$path")"
  for d in "$projects"/*/; do
    d="${d%/}"
    [ "$(printf '%s' "$(basename "$d")" | tr 'A-Z' 'a-z')" = "$k" ] || continue
    case $'\n'"$matched"$'\n' in *$'\n'"$d"$'\n'*) continue ;; esac
    matched="$matched${matched:+$'\n'}$d"
  done
done <<< "$candidates"

if [ -z "$matched" ]; then
  echo "no project directory under $projects matches $project"
  echo "run with --all to see every project that has memories"
  exit 0
fi

while IFS= read -r d; do report "$d"; done <<< "$matched"
