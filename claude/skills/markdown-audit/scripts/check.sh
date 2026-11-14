#!/usr/bin/env bash
# Make the fixed checks of a Markdown audit and print a report.
#
#   check.sh [project-dir] [--no-pre-commit]
#
# Lists the CLAUDE.md files in force, runs pre-commit on every file, and
# reports pattern hits against the writing rules, file lengths, and the link
# graph. Only pre-commit's fixers change files; --no-pre-commit skips them.
set -euo pipefail

project="."
run_pre_commit=1
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --no-pre-commit) run_pre_commit=0; shift ;;
    -h|--help)       sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*)              echo "unknown option: $1" >&2; exit 2 ;;
    *)               project="$1"; shift ;;
  esac
done

[ -d "$project" ] || { echo "no such directory: $project" >&2; exit 1; }
cd "$project"
git=0
git rev-parse --git-dir >/dev/null 2>&1 && git=1
[ "$git" = 1 ] && cd "$(git rev-parse --show-toplevel)"
echo "project: $(pwd)"

# Tracked files only, so build output and vendored packages stay out.
md=()
if [ "$git" = 1 ]; then
  while IFS= read -r f; do [ -f "$f" ] && md+=("$f"); done \
    < <(git ls-files -- '*.md' '*.markdown')
else
  while IFS= read -r f; do md+=("${f#./}"); done \
    < <(find . \( -name .git -o -name node_modules \) -prune -o \
          -type f \( -name '*.md' -o -name '*.markdown' \) -print | sort)
fi
echo "markdown files: ${#md[@]}"

echo
echo "instructions in force:"
global="${CLAUDE_HOME:-$HOME/.claude}/CLAUDE.md"
if [ -f "$global" ]; then echo "  $global (global: the owner's style)"; fi
found=0
for f in "${md[@]}"; do
  case "$f" in
    CLAUDE.md)   echo "  CLAUDE.md (the repo's)"; found=1 ;;
    */CLAUDE.md) echo "  $f (applies under ${f%/CLAUDE.md}/)"; found=1 ;;
  esac
done
[ "$found" = 1 ] || echo "  (no CLAUDE.md in the repo)"

echo
echo "pre-commit:"
if [ "$run_pre_commit" = 0 ]; then
  echo "  skipped (--no-pre-commit)"
elif [ ! -f .pre-commit-config.yaml ]; then
  echo "  no .pre-commit-config.yaml (repo-template-check offers one)"
elif ! command -v pre-commit >/dev/null 2>&1; then
  echo "  pre-commit is not installed"
else
  # A snapshot of the working tree, taken without touching it, so the
  # fixers' changes can be told apart from edits already there.
  base=HEAD
  if [ "$git" = 1 ] && [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "  the working tree had uncommitted changes before the run"
    base="$(git stash create)"
  fi
  if out="$(pre-commit run --all-files --color never 2>&1)"; then
    echo "  every hook passed"
  else
    printf '%s\n' "$out" | grep -Ev '(Passed|Skipped)$' | sed 's/^/  /'
  fi
  if [ "$git" = 1 ] && ! git diff --quiet "$base"; then
    echo "  the fixers changed:"
    git diff --stat "$base" | sed 's/^/    /'
  fi
fi

echo
echo "pattern hits (file:line: rule: text):"
hits=""
[ "${#md[@]}" = 0 ] || hits="$(awk -f "$here/patterns.awk" "${md[@]}" | awk '!seen[$0]++')"
if [ -n "$hits" ]; then printf '%s\n' "$hits" | sed 's/^/  /'; else echo "  (none)"; fi

echo
echo "lengths worth a look (README past 150 lines, others past 400, any under 20):"
long=0
for f in "${md[@]}"; do
  n="$(wc -l <"$f")"
  limit=400
  case "$f" in README.md|*/README.md) limit=150 ;; esac
  if [ "$n" -gt "$limit" ]; then echo "  $f: $n lines, past $limit"; long=1
  elif [ "$n" -lt 20 ]; then echo "  $f: $n lines, under 20"; long=1
  fi
done
[ "$long" = 1 ] || echo "  (none)"

echo
echo "links:"
[ "${#md[@]}" = 0 ] || awk -f "$here/links.awk" "${md[@]}"
if [ -d plans ] && [ ! -f TODO.md ]; then
  echo "  plans/ exists with no TODO.md to order it"
fi
