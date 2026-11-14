# Plan: check prose by machine

## Goal

Check the writing rules in [claude/CLAUDE.md](../claude/CLAUDE.md) by machine, so a broken rule is flagged rather than left to Claude's memory or a reread.

## The options

Three, to decide together, since they cover the same rules: a hook after Claude writes Markdown, Vale, and a Markdown check at commit.

### Check Markdown after Claude writes it

- **What it catches:** em dashes and words that date a sentence, as Claude writes them, so it fixes them in the same turn. Claude put "today" into TODO.md while drafting [Check prose with Vale](#check-prose-with-vale), and caught it only on rereading.
- **Form:** a `PostToolUse` hook on `Edit` and `Write` for `.md` files that runs the markdown-audit skill's [patterns.awk](../claude/skills/markdown-audit/scripts/patterns.awk) on the file and hands what it finds back to Claude, so the patterns live in one script.
- **Overlap:** a check at commit also catches the owner's own edits; this hook catches only Claude's, but sooner.

### Check prose with Vale

[Vale](https://vale.sh) is a linter for prose.

What it adds over a `grep` check:

- It reads Markdown, so it skips front matter, code blocks and inline code.
- Each rule has a level, and only errors fail a run. An em dash can be an error while a possible passive stays a hint, which leaves Orwell's sixth rule to the reader.
- Word lists such as write-good's `TooWordy` and `Cliches`, and substitution rules that suggest the short word, cover rules `grep` cannot.
- Its `vale-commit-msg` hook applies the same rules to commit messages.

It cannot check one sentence per line, stale counts, or whether a paragraph gets to the point.

What it costs:

- **A runtime.** Its pre-commit hook is `language: golang`, so pre-commit fetches Go as it does for `gitleaks`. The editor and a run by hand need the binary: `winget install -e --id errata-ai.Vale`.
- **A third word list.** Turn its spelling rule off, for the reason in [the spelling plan](spelling.md).
- **Vendored styles.** `vale sync` downloads packages such as write-good. Either sync on each machine, or write a small style of our own that borrows the lists worth having.
- **Noise.** write-good's `Passive` flags a form of "be" followed by a word ending in "ed", so it misses "is written" and flags "is based". Its `E-Prime` flags every "is".

Vale always loads a user-level `.vale.ini`, at `%LOCALAPPDATA%\vale\.vale.ini` on Windows, and lays a project's file over it.
So `install.sh` could place a style as one more target, which suits the editor and a run by hand.
A commit gate must not depend on that file, because a machine without these dotfiles would get different results.
A gate's style travels with the repo, through [repo-template](https://github.com/francisco-camargo/repo-template).

## Steps

- [ ] Try Vale: install the binary, write a user-level `.vale.ini` with a small style (em dashes, litotes, and dating words as errors; write-good's `Passive`, `TooWordy` and `Cliches` as warnings), run `vale README.md TODO.md`, and judge whether the warnings are worth reading.
- [ ] Choose among the hook, Vale, and a check at commit.
- [ ] Add each chosen check, one commit each.

## Docs to update

- [ ] [docs/hooks.md](../docs/hooks.md): a section for the hook, if it is added.
- [ ] repo-template's `.pre-commit-config.yaml` and README: the check at commit, if it is added, since it belongs in every project.
- [ ] `README.md`: the hook or the Vale style, in the file table.

## Updates to send

None.

## Open questions

- **Vale or `grep`:** keep Vale if its warnings are worth reading; otherwise a `grep` hook covers the error-level rules.

## Done when

An em dash or "today" written into a Markdown file is flagged by machine, before Claude's turn ends or at commit.
