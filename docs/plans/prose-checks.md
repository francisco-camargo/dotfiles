# Plan: check prose by machine

Two ways to check the writing rules in [claude/CLAUDE.md](../../claude/CLAUDE.md) by machine, to decide together, along with a Markdown check at commit.

## Check Markdown after Claude writes it

- **What it catches:** em dashes and words that date a sentence, as Claude writes them, so it fixes them in the same turn. Claude put "today" into TODO.md while drafting [Check prose with Vale](#check-prose-with-vale), and caught it only on rereading.
- **Form:** a `PostToolUse` hook on `Edit` and `Write` for `.md` files that searches the file and hands what it finds back to Claude.
- **Overlap:** [Check prose with Vale](#check-prose-with-vale) and a Markdown check at commit cover the same rules. A check at commit also catches my own edits; this hook catches only Claude's, but sooner. Decide the three together.

## Check prose with Vale

[Vale](https://vale.sh) is a linter for prose.
It could check the writing rules in [claude/CLAUDE.md](../../claude/CLAUDE.md), which hold only as far as Claude remembers them.

What it adds over a `grep` check:

- It reads Markdown, so it skips front matter, code blocks and inline code.
- Each rule has a level, and only errors fail a run. An em dash can be an error while a possible passive stays a hint, which leaves Orwell's sixth rule to the reader.
- Word lists such as write-good's `TooWordy` and `Cliches`, and substitution rules that suggest the short word, cover rules `grep` cannot.
- Its `vale-commit-msg` hook applies the same rules to commit messages.

It cannot check one sentence per line, stale counts, or whether a paragraph gets to the point.

What it costs:

- **A runtime.** Its pre-commit hook is `language: golang`, so pre-commit fetches Go as it does for `gitleaks`. The editor and a run by hand need the binary: `winget install -e --id errata-ai.Vale`.
- **A third word list.** Turn its spelling rule off, for the reason in [Settle how spelling gets checked](../../TODO.md#settle-how-spelling-gets-checked).
- **Vendored styles.** `vale sync` downloads packages such as write-good. Either sync on each machine, or write a small style of our own that borrows the lists worth having.
- **Noise.** write-good's `Passive` flags a form of "be" followed by a word ending in "ed", so it misses "is written" and flags "is based". Its `E-Prime` flags every "is".

Vale always loads a user-level `.vale.ini`, at `%LOCALAPPDATA%\vale\.vale.ini` on Windows, and lays a project's file over it.
So `install.sh` could place a style as one more target, which suits the editor and a run by hand.
A commit gate must not depend on that file, because a machine without these dotfiles would get different results.
A gate's style travels with the repo, through [repo-template](https://github.com/francisco-camargo/repo-template).

To try it before adopting it:

1. Install the binary.
2. Write a user-level `.vale.ini` with a small style: em dashes, litotes, and words that date a document as errors; write-good's `Passive`, `TooWordy` and `Cliches` as warnings.
3. Run `vale README.md TODO.md` and judge whether the warnings are worth reading.

Keep it if they are.
If not, a `grep` hook covers the error-level rules.
