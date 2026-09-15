---
name: md-to-pdf
description: Render a Markdown document to a print-ready PDF. Use when asked to export, print, or "save as PDF" any .md file, or to regenerate the PDF after editing the Markdown.
---

# Markdown to PDF

Converts a Markdown file to a PDF laid out for printing and handing out on
paper.

## Usage

```bash
~/.claude/skills/md-to-pdf/scripts/md2pdf.sh roles_and_responsibilities.md
```

Writes `roles_and_responsibilities.pdf` next to the source. Options:

| Flag | Effect |
| --- | --- |
| `<output.pdf>` (2nd positional arg) | Write somewhere other than `<input>.pdf` |
| `--css <file>` | Use a different stylesheet instead of `assets/print.css` |
| `--keep-html` | Keep the intermediate HTML and print its path, for debugging layout |

Set `MD2PDF_BROWSER` to a Chrome/Edge executable if the script cannot find one.

## How it works

1. `scripts/md2html.awk` converts the Markdown to HTML.
2. `assets/print.css` is inlined into that HTML.
3. A headless Chrome or Edge prints it with `--print-to-pdf`.

No pandoc, node, or python needed: only `awk` and an installed Chromium-family
browser. This matters: none of the usual converters are installed on the
machine this config is installed on.

## Scope of the converter

`md2html.awk` is intentionally small. It handles headings, GFM pipe tables,
flat bulleted and numbered lists, paragraphs, `**bold**`, and `` `code` ``,
which is all the target documents use. Anything else (nested lists, links,
images, block quotes, fenced code) passes through as literal text. If a
document starts needing those, extend the awk script rather than reaching for
a heavier toolchain.

## Adjusting the layout

Layout lives entirely in `assets/print.css`. Things worth knowing:

- Page is US Letter with 0.6in / 0.55in margins, set via `@page`.
- `thead { display: table-header-group }` repeats column headers on every page.
- `tr { page-break-inside: avoid }` stops rows splitting across a page break.
- `h2`/`h3` use `page-break-after: avoid` so a section heading is never orphaned
  at the bottom of a page.
- Fixed column widths apply only to four-column tables, the
  Task / Owner / Backup / Cadence shape. Other tables size columns to fit.

## After regenerating

The PDF is a build output. Re-run the script whenever the Markdown changes
rather than editing the PDF, and mention to the user that it needs committing
if they track it.
