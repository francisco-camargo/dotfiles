# dotfiles

Configuration files kept in one place so every machine behaves the same.

## Motivation

This repo holds the configuration I want on every machine and in every project.
It covers Claude Code: its settings and [hooks](#hooks), the [instructions](#standing-instructions) it reads each session, and its [skills](#skills).
[What's here](#whats-here) lists each file and where it installs.
[Candidates for later](TODO.md#what-else-could-live-here) are git config, VS Code settings, a shell profile, and the files each repo repeats, such as `.gitignore` and `.gitattributes`.

When I settle how a tool should behave, through a setting, a hook, or a rule for Claude, I want to do it **once**, not once per repo or once per machine.
The hook that makes Claude ask before `git commit` shows the idea: written once here, it holds in every repo on every machine that runs `install.sh`.
`.gitattributes` shows the opposite: I have written it by hand in more than one repo.

If dotfiles are new to you, [docs/background.md](docs/background.md) says what they are and why this repo links its files into your home directory.

## The working loop

Edit a file here, commit it, and `git pull` on the other machines.
With symlinks, the change takes effect at once.

The link works the other way too.
Claude Code edits `~/.claude/settings.json` itself when you change a `/config` option stored in user settings, such as the theme.
That shows up here as an uncommitted change to `claude/settings.json`, which can conflict on the next `git pull`.
Commit it if every machine should have it, or `git restore` it if not.

Windows refuses symlinks to an ordinary user until Developer Mode is on, so `install.sh` copies instead.
Until then, run `./install.sh` again after each edit, or the change never reaches `~/.claude/` ([Symlinks on Windows](docs/install.md#symlinks-on-windows)).

## Install on a new machine

On Windows, [turn on Developer Mode first](docs/install.md#on-windows-turn-on-developer-mode-first).

See what `install.sh` would do first.
`--dry-run` changes nothing:

```bash
git clone https://github.com/francisco-camargo/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./install.sh --dry-run
```

It prints every move it would make.
When that reads the way you want, drop the flag:

```bash
./install.sh
```

Where a file is already there and differs from this repo's, `install.sh` shows you which and asks whether to keep it, replace it, or see the difference.
If you already have a `~/.claude/settings.json`, read [`install.sh` and an existing `settings.json`](docs/install.md#installsh-and-an-existing-settingsjson) first.

[docs/install.md](docs/install.md) covers what the installer links, the VS Code settings it needs, its flags, platform support, and what to watch for on Windows.

## What's here

| Path | Goes to | What it is |
| --- | --- | --- |
| `claude/settings.json` | `~/.claude/settings.json` | Model choice, and the [hooks](#hooks) below |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | [Standing instructions](#standing-instructions) for every session, everywhere |
| `claude/skills/md-to-pdf/` | `~/.claude/skills/md-to-pdf/` | A [skill](#skills) that renders a Markdown file to a print-ready PDF |
| `claude/skills/repo-template-check/` | `~/.claude/skills/repo-template-check/` | A [skill](#skills) that checks a repo against repo-template |
| `claude/skills/memory-audit/` | `~/.claude/skills/memory-audit/` | A [skill](#skills) that moves Claude's per-project memories into visible files |

## Hooks

`claude/settings.json` holds `PreToolUse` hooks, called gates, that run before a Bash or PowerShell tool call:

- **The git approval gate** asks before `git commit` or `git push`.
- **The sed gate** refuses `sed` edits.
- **The uv gate** refuses a bare `python` and points to `uv`.

[docs/hooks.md](docs/hooks.md) explains each gate and the rules to keep when you edit one.

## Skills

A skill pairs a script with the description that tells Claude when to use it.

### The md-to-pdf skill

```bash
~/.claude/skills/md-to-pdf/scripts/md2pdf.sh some-document.md
```

`md2pdf.sh` converts Markdown to HTML with a small awk script, inlines `assets/print.css`, and prints it with headless Chrome or Edge.
It needs no pandoc or node.
The stylesheet holds all the layout, including page breaks and repeated table headers.
See `claude/skills/md-to-pdf/SKILL.md` for details.

### The repo-template-check skill

Ask Claude to check a repo against [repo-template](https://github.com/francisco-camargo/repo-template), which holds the files every project starts with.

```bash
~/.claude/skills/repo-template-check/scripts/check.sh some-project
```

The script does what code can settle: which template files the project lacks, which match, and which template lines a differing copy lacks.
Claude does the rest: it offers the missing files, explains each gap, and suggests what to adopt, changing nothing until asked.
See `claude/skills/repo-template-check/SKILL.md` for details.

### The memory-audit skill

Ask Claude to audit a project's memories.
Claude Code keeps them outside every repo, where they shape sessions without anyone seeing them.

```bash
~/.claude/skills/memory-audit/scripts/find.sh some-project
```

The script finds the project's memory directory and prints every memory; `--all` covers every project.
Claude then proposes a visible home for each one, such as a `CLAUDE.md`, a hook, or the README, and waits for approval.
Once approved, it commits each move and deletes the memory after the commit lands.
See `claude/skills/memory-audit/SKILL.md` for details.

### Skill scope, and duplicates

A skill installed here lands in `~/.claude/skills/` and is available in every project.
A skill committed to a repo's own `.claude/skills/` is available only in that repo.
When the same skill name exists in both, the project copy wins.
Two copies of one skill is a problem to fix by deleting one, not by keeping both.

## Standing instructions

`claude/CLAUDE.md` installs as `~/.claude/CLAUDE.md`, the instructions Claude reads at the start of every session in every project.
It holds preferences and facts about the environment that would otherwise need saying again in each session.

[docs/standing-instructions.md](docs/standing-instructions.md) explains what goes in it, what goes in a skill instead, and why.

## Security

[docs/security.md](docs/security.md) covers what this repo keeps out of git, the gates that stop a secret before it is committed, and what GitHub checks on push.

## Open items

Work that is started and unfinished is in [TODO.md](TODO.md#open-items), along with [what else could live here](TODO.md#what-else-could-live-here).
