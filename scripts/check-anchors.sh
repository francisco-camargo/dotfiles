#!/usr/bin/env bash
# Fail if a Markdown link points at a heading that is not there.
#
# This is the staleness a rename leaves behind: the heading moves, the links
# keep the old slug, and nothing says so until a reader clicks one. A commit
# that renames a heading should fix its links in the same commit.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# GitHub builds an anchor by lowercasing the heading, dropping anything that is
# not a letter, digit, space or hyphen, then turning spaces into hyphens.
# Repeated headings would need -1, -2 suffixes; this repo has none, and the
# duplicate check below keeps it that way.
slugs() {
  awk '
    /^#+ / {
      heading = $0
      sub(/^#+[ \t]+/, "", heading)
      slug = tolower(heading)
      gsub(/[^a-z0-9 -]/, "", slug)
      gsub(/ /, "-", slug)
      print slug
    }
  ' "$1"
}

problems="$(
  for file in $(git ls-files '*.md'); do
    dupes="$(slugs "$file" | sort | uniq -d)"
    if [ -n "$dupes" ]; then
      printf '%s: headings collide into one anchor, so links to them are ambiguous:\n' "$file"
      printf '  %s\n' $dupes
    fi

    for raw in $(grep -oE '\]\([^) ]*#[A-Za-z0-9._-]+\)' "$file" || true); do
      link="${raw#](}"
      link="${link%)}"
      target="${link%%#*}"
      anchor="${link#*#}"

      if [ -z "$target" ]; then
        dest="$file"
      else
        dest="$(dirname "$file")/$target"
        dest="${dest#./}"
      fi

      if [ ! -f "$dest" ]; then
        printf '%s: link to a file that is not here: %s\n' "$file" "$target"
        continue
      fi

      if ! slugs "$dest" | grep -qxF "$anchor"; then
        printf '%s: no heading in %s makes the anchor #%s\n' "$file" "$dest" "$anchor"
      fi
    done
  done
)"

if [ -n "$problems" ]; then
  printf '%s\n' "$problems" >&2
  exit 1
fi
