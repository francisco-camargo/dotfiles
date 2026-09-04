# dotfiles

Claude Code configuration, kept in one place so every machine behaves the same.

## Install on a new machine

```bash
git clone https://github.com/francisco-camargo/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./install.sh
```

Then restart Claude Code, or open `/hooks` once, so it reloads settings.

`install.sh` symlinks `claude/settings.json` and `claude/skills/md-to-pdf` into
`~/.claude/`. Anything already there is moved to `<name>.bak.<timestamp>` first —
nothing is silently overwritten. Use `--dry-run` to preview, `--copy` to force
copies instead of links.

### Symlinks on Windows

Windows only allows symlinks with Developer Mode on (Settings → System → For
developers) or an elevated shell. Without it the script notices, says so, and
copies instead. Copies work fine, but they do not track edits — after changing
anything in this repo, re-run `./install.sh` to push the change back out.

## What's here

| Path | Goes to | What it is |
| --- | --- | --- |
| `claude/settings.json` | `~/.claude/settings.json` | Model choice and the git approval gate below |
| `claude/skills/md-to-pdf/` | `~/.claude/skills/md-to-pdf/` | Renders a Markdown file to a print-ready PDF |

## The git approval gate

`claude/settings.json` requires explicit approval before Claude runs
`git commit` or `git push`. Three layers, because the first two have gaps:

1. **`hooks.PreToolUse`** — a sed+grep command that reads the command out of the
   tool payload and forces an approval prompt when it matches
   `git[^;&|]{0,60}(commit|push)`. This is the layer that matters: it catches
   compound commands like `cd /repo && git commit`, which the prefix-matching
   permission rules below miss entirely.
2. **`permissions.ask`** — rules for `Bash(git commit:*)`, `Bash(git push:*)`
   and the PowerShell equivalents. `ask` rules beat `allow` rules, so a project
   cannot grant itself permission later.
3. **`autoMode.soft_deny`** — stops auto mode's classifier from self-approving a
   commit, and spells out that "save this" or "version this" is not
   authorization.

The hook uses only `sed` and `grep` — no `jq`, `node`, or `python`, none of
which are reliably installed. Keep it that way, or it will silently stop firing
on a machine that lacks the dependency.

To tighten it from "prompt me" to "never, I'll run git myself", move the entries
from `permissions.ask` to `permissions.deny`.

## The md-to-pdf skill

```bash
~/.claude/skills/md-to-pdf/scripts/md2pdf.sh some-document.md
```

Converts Markdown to HTML with a small awk script, inlines `assets/print.css`,
and prints it with headless Chrome or Edge. No pandoc or node needed. Layout,
including page breaks and repeated table headers, is all in the stylesheet.
See `claude/skills/md-to-pdf/SKILL.md` for details.
