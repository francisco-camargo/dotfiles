#!/usr/bin/env bash
# Render a Markdown file to PDF using a headless Chromium browser.
#
#   md2pdf.sh <input.md> [output.pdf] [--css <file>] [--keep-html]
#
# Defaults the output to <input>.pdf next to the source. No pandoc, node or
# python required -- just awk and an installed Chrome/Edge.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(dirname "$here")"

css="$skill_dir/assets/print.css"
awk_script="$here/md2html.awk"
keep_html=0
input=""
output=""

while [ $# -gt 0 ]; do
  case "$1" in
    --css)       css="$2"; shift 2 ;;
    --keep-html) keep_html=1; shift ;;
    -h|--help)   sed -n '2,7p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*)          echo "unknown option: $1" >&2; exit 2 ;;
    *)           if [ -z "$input" ]; then input="$1"; else output="$1"; fi; shift ;;
  esac
done

[ -n "$input" ] || { echo "usage: md2pdf.sh <input.md> [output.pdf]" >&2; exit 2; }
[ -f "$input" ] || { echo "no such file: $input" >&2; exit 1; }
[ -f "$css" ]   || { echo "no such stylesheet: $css" >&2; exit 1; }
[ -n "$output" ] || output="${input%.md}.pdf"

# Locate a Chromium-family browser: PATH first, then the usual Windows/macOS spots.
browser=""
for candidate in \
  "${MD2PDF_BROWSER:-}" \
  "$(command -v google-chrome || true)" \
  "$(command -v chromium || true)" \
  "$(command -v chromium-browser || true)" \
  "$(command -v msedge || true)" \
  "/c/Program Files/Google/Chrome/Application/chrome.exe" \
  "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
  "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
  "/c/Program Files/Microsoft/Edge/Application/msedge.exe" \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" ; do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then browser="$candidate"; break; fi
done
[ -n "$browser" ] || {
  echo "no Chrome/Edge found; set MD2PDF_BROWSER to the executable" >&2; exit 1; }

# BSD mktemp (macOS) may reject a bare -d without a template; fall back to -t.
work="$(mktemp -d 2>/dev/null || mktemp -d -t md2pdf)"
html="$work/page.html"
trap '[ "$keep_html" -eq 1 ] || rm -rf "$work"' EXIT

title="$(basename "${input%.md}")"
{
  printf '<!doctype html>\n<html><head><meta charset="utf-8"><title>%s</title>\n<style>\n' "$title"
  cat "$css"
  printf '</style></head><body>\n'
  awk -f "$awk_script" "$input"
  printf '</body></html>\n'
} > "$html"

# Chrome on Windows needs native paths; cygpath is present under Git Bash.
to_native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
to_url()    { if command -v cygpath >/dev/null 2>&1; then printf 'file:///%s' "$(cygpath -m "$1")"; else printf 'file://%s' "$1"; fi; }

mkdir -p "$(dirname "$output")"

# Chrome resolves --print-to-pdf against its own cwd, so hand it an absolute path.
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"

"$browser" \
  --headless=new --disable-gpu --no-sandbox --no-pdf-header-footer \
  --user-data-dir="$(to_native "$work/profile")" \
  --print-to-pdf="$(to_native "$output")" \
  "$(to_url "$html")" >/dev/null 2>&1

[ -s "$output" ] || { echo "browser produced no PDF" >&2; exit 1; }
[ "$keep_html" -eq 1 ] && echo "html: $html"
echo "wrote $output ($(wc -c < "$output" | tr -d ' ') bytes)"
