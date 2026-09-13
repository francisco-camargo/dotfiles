#!/usr/bin/env bash
# Compare a project with the files repo-template gives every project.
#
#   check.sh [project-dir] [--template <repo-template clone>]
#
# Reports each template file as missing, identical, or differing, and for one
# that differs, the template's lines the project's copy lacks. Changes nothing
# in the project.
set -euo pipefail

project="."
template_repo="${REPO_TEMPLATE:-$HOME/git/repo-template}"
url="https://github.com/francisco-camargo/repo-template.git"

while [ $# -gt 0 ]; do
  case "$1" in
    --template) template_repo="$2"; shift 2 ;;
    -h|--help)  sed -n '2,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*)         echo "unknown option: $1" >&2; exit 2 ;;
    *)          project="$1"; shift ;;
  esac
done

[ -d "$project" ] || { echo "no such directory: $project" >&2; exit 1; }
project="$(cd "$project" && pwd)"

# Without a local clone, compare against a fresh one from GitHub.
if [ -d "$template_repo/template" ]; then
  template_repo="$(cd "$template_repo" && pwd)"
  origin="local clone"
  if git -C "$template_repo" fetch --quiet 2>/dev/null; then
    behind="$(git -C "$template_repo" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo "?")"
    [ "$behind" = 0 ] || origin="$origin, $behind commits behind its upstream"
  else
    origin="$origin, could not fetch to check it is current"
  fi
  [ -z "$(git -C "$template_repo" status --porcelain -- template)" ] \
    || origin="$origin, with uncommitted changes in template/"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 "$url" "$tmp/repo-template"
  template_repo="$tmp/repo-template"
  origin="fresh clone of $url"
fi
template="$template_repo/template"
version="$(git -C "$template_repo" describe --tags --always 2>/dev/null || echo unknown)"

echo "template: $template_repo ($version, $origin)"
echo "project:  $project"

if git -C "$project" rev-parse --git-dir >/dev/null 2>&1; then
  hooks="$(cd "$project" && git rev-parse --git-path hooks)"
  case "$hooks" in /*) ;; *) hooks="$project/$hooks" ;; esac
  if grep -qs pre-commit "$hooks/pre-commit"; then
    echo "  pre-commit hook: installed"
  else
    echo "  pre-commit hook: not installed"
  fi
  visibility="unknown"
  if command -v gh >/dev/null 2>&1; then
    visibility="$(cd "$project" && gh repo view --json visibility -q .visibility 2>/dev/null || echo unknown)"
  fi
  echo "  GitHub visibility: $visibility"
else
  echo "  not a git repository"
fi

# Lines of the template file ($1) that the project file ($2) lacks, compared
# with line endings, surrounding whitespace, and trailing comments stripped.
# Blank lines and comments are skipped: they carry no setting.
lacking() {
  awk '
    { sub(/\r$/, ""); sub(/[ \t]+#.*$/, ""); gsub(/^[ \t]+|[ \t]+$/, "") }
    $0 == "" || /^(#|\/\/)/ { next }
    FILENAME == ARGV[1] { have[$0] = 1; next }
    !($0 in have) { print "      " $0 }
  ' "$2" "$1"
}

missing=""
identical=""
differs=""
while IFS= read -r rel; do
  rel="${rel#./}"
  if [ ! -e "$project/$rel" ]; then
    missing="$missing  $rel"$'\n'
  elif diff -q --strip-trailing-cr "$template/$rel" "$project/$rel" >/dev/null; then
    identical="$identical  $rel"$'\n'
  else
    lines="$(lacking "$template/$rel" "$project/$rel")"
    differs="$differs  $rel"$'\n'
    if [ -n "$lines" ]; then
      differs="$differs    template lines the project lacks:"$'\n'"$lines"$'\n'
    else
      differs="$differs    lacks no template lines; differs only in comments, spacing, or its own additions"$'\n'
    fi
  fi
done < <(cd "$template" && find . -type f | sort)

section() {
  echo
  echo "$1:"
  if [ -n "$2" ]; then printf '%s' "$2"; else echo "  (none)"; fi
}
section missing "$missing"
section identical "$identical"
section differs "$differs"
