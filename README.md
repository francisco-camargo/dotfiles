# dotfiles

Configuration files kept in one place so every machine behaves the same.

## Motivation

This repo holds the configuration I want on every machine and in every project.
It covers Claude Code: its settings and [hooks](#hooks), the [instructions](#standing-instructions) it reads each session, and its [skills](#skills).
[What's here](#whats-here) lists each file and where it installs.
[Candidates for later](TODO.md#later) are git config, VS Code settings, a shell profile, and the files each repo repeats, such as `.gitignore` and `.gitattributes`.

When I settle how a tool should behave, through a setting, a hook, or a rule for Claude, I want to do it **once**, not once per repo or once per machine.
The hook that makes Claude ask before `git commit` shows the idea: written once here, it holds in every repo on every machine that runs `install.sh`.
`.gitattributes` shows the opposite: I have written it by hand in more than one repo.

If dotfiles are new to you, [docs/background.md](docs/background.md) says what they are and why this repo links its files into your home directory.

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

## The working loop

Edit a file here, commit it, and `git pull` on the other machines.
With symlinks, the change takes effect at once.

The link works the other way too.
Claude Code edits `~/.claude/settings.json` itself when you change a `/config` option stored in user settings, such as the theme.
That shows up here as an uncommitted change to `claude/settings.json`, which can conflict on the next `git pull`.
Commit it if every machine should have it, or `git restore` it if not.

Windows refuses symlinks to an ordinary user until Developer Mode is on, so `install.sh` copies instead.
Until then, run `./install.sh` again after each edit, or the change never reaches `~/.claude/` ([Symlinks on Windows](docs/install.md#symlinks-on-windows)).

## What's here

| Path | Goes to | What it is |
| --- | --- | --- |
| `claude/settings.json` | `~/.claude/settings.json` | Model choice, and the [hooks](docs/hooks.md) |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | [Standing instructions](docs/standing-instructions.md) for every session, everywhere |
| `claude/skills/md-to-pdf/` | `~/.claude/skills/md-to-pdf/` | A [skill](claude/skills/md-to-pdf/SKILL.md) that renders a Markdown file to a print-ready PDF |
| `claude/skills/repo-template-check/` | `~/.claude/skills/repo-template-check/` | A [skill](claude/skills/repo-template-check/SKILL.md) that checks a repo against repo-template |
| `claude/skills/memory-audit/` | `~/.claude/skills/memory-audit/` | A [skill](claude/skills/memory-audit/SKILL.md) that moves Claude's per-project memories into visible files |
| `claude/skills/planning/` | `~/.claude/skills/planning/` | A [skill](claude/skills/planning/SKILL.md) that writes plans in `plans/` and keeps `TODO.md` in step |

## Hooks

`claude/settings.json` holds `PreToolUse` hooks, called gates, that run before a Bash or PowerShell tool call:

- **The git approval gate** asks before `git commit` or `git push`.
- **The sed gate** refuses `sed` edits.
- **The uv gate** refuses a bare `python` and points to `uv`.

[docs/hooks.md](docs/hooks.md) explains each gate and the rules to keep when you edit one.

## Skills

A skill pairs a script with the description that tells Claude when to use it.
Ask Claude for the task, and it runs the skill:

- **[md-to-pdf](claude/skills/md-to-pdf/SKILL.md)** renders a Markdown file to a print-ready PDF through headless Chrome or Edge, with no pandoc or node.
- **[repo-template-check](claude/skills/repo-template-check/SKILL.md)** compares a repo with [repo-template](https://github.com/francisco-camargo/repo-template), the files every project starts with, and offers what is missing.
- **[memory-audit](claude/skills/memory-audit/SKILL.md)** finds Claude Code's per-project memories and, once you approve, moves each into a file you can see.
- **[planning](claude/skills/planning/SKILL.md)** writes a plan for a piece of work in `plans/`, with steps ticked off as commits land, and keeps `TODO.md` a short, ordered list that links to the plans.

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

[TODO.md](TODO.md) lists the work ahead in priority order, and [plans/](plans/) holds a plan for each item that needs one.
