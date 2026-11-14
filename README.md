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

## Introduction

### What dotfiles are

Most programs keep their settings in plain files in your home directory.
On Unix the names start with a dot, as in `.bashrc`, `.gitconfig` and `.vimrc`, which hides them from a plain `ls`.
Hence the name *dotfiles*.
`~/.claude/` follows the same convention, with the dot on the directory.

### The problem they solve

Without a repo, such a config file:

1. **Has no history.** Six months after changing a setting, you cannot recall what you changed or why.
2. **Drifts between machines.** You notice only when something behaves differently on one of them.
3. **Is lost on reinstall.** A new machine means rebuilding it from memory.

### Symlinks

A dotfiles repo makes the repo the real location, and the home directory a set of links to it.
`~/.claude/settings.json` becomes a **symlink**, a file that points to another path, here `claude/settings.json` in this repo.
Editing either path edits the repo.
`install.sh` creates the links.

That brings git to config:

- **One copy.** Each file exists once, and that copy is the current one.
- **A history.** Each change is a commit, so `git log` shows why a setting is what it is, and `git revert` undoes it.
- **Reproducible machines.** `git clone` and `./install.sh` make a new machine behave like the others.
- **Documentation.** The sections below explain what each piece does.

### The working loop

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

`~/.claude/CLAUDE.md` holds standing instructions Claude reads at the start of every session in every project: the home for preferences I would otherwise explain again and again.
The repo keeps it as `claude/CLAUDE.md`, and `install.sh` installs it like everything else.
The entries arrived two ways: some I had said once already and would otherwise say again, and some are standards set up front.

### The bug that makes the case for it

This machine gives Claude two shell tools, PowerShell and Bash, and their multi-line string syntax is not interchangeable.
PowerShell uses a here-string:

```powershell
git commit -m @'
subject line
'@
```

Bash uses a heredoc:

```bash
git commit -F - <<'MSG'
subject line
MSG
```

Feed the PowerShell form to the Bash tool and nothing errors.
Bash has no idea `@'` is meant to open anything, so it passes the `@` through as an ordinary character.
The commit succeeds, with `@` and a space glued to the front of the subject and a stray `@` alone on the last line of the body.
Nothing complains, the tool reports success, and it looks fine until someone reads the log.
The repair is an amend.

That happened here while making commit `116e4ff`, and the mistake recurs rather than teaching itself: neither tool signals the mismatch, and any setup that exposes both shells invites it.

A global `CLAUDE.md` is for this.
It holds standing facts about the environment that need saying once, somewhere lasting, rather than one-off errors:

> When a session exposes both a PowerShell tool and a Bash tool, their syntaxes do not mix.
>
> In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
> The PowerShell here-string `@'...'@` is not Bash syntax and does not fail: Bash passes the `@` through as an ordinary character, silently embedding it in the text.
>
> In the PowerShell tool, write `A; if ($?) { B }` in place of `A && B`: `&&` and `||` are parse errors in Windows PowerShell 5.1.

The general rule: anything corrected in two different sessions is a candidate.
A correction made only in a conversation ends with it.

### The preference that makes the same case

The wrapping convention is not a bug, which is the point: the file is for anything I would otherwise explain again, and preferences qualify.
Prose here was hard-wrapped to eighty columns, which splits sentences across lines and makes a one-word edit reflow every line after it: the diff reports a paragraph changed when a word did.
The convention that fixes it is one sentence per line, breaking at sentence boundaries only.
Markdown joins the lines back into a paragraph when rendered, so the output is identical and only the diffs improve.

Left in a conversation, that preference lasts until the conversation ends, and the next session goes back to wrapping at eighty.
Written down here, it holds in every repo, including ones that have never heard of it.

I wrote this README in the old style and converted it in one pass, as the rule asks: a whole-file change of its own rather than a paragraph quietly reflowed while editing something else.

### The entry chosen rather than corrected

Orwell's six rules from *Politics and the English Language* are in there too.
Where the wrapping rule governs the line breaks, these govern the words: cut what can be cut, prefer the short word, prefer the active, and skip the jargon when a plain word carries the same meaning.
His sixth rule, to break any of them sooner than say anything barbarous, limits the other five, and that matters because a style rule applied past the point of sense costs more than it saves.

That entry arrived differently from the ones above.
Nothing went wrong first: no mangled commit, no paragraph reflowed for one word.
It is a standard set up front, which is the other fair way in.
The bar is not only "this has gone wrong twice"; it is also "this is general and lasting enough to say before it costs anything".
What stays out is the preference that applies to one file, or the rule that would surprise a reader six months from now.

### Instructions are not enforcement

This approach has a limit.
`CLAUDE.md` is advice the model reads, not a rule the machine applies: it lowers the odds and does not remove them.
The `PreToolUse` hook that gates commits could enforce this one: match `@'` in a Bash tool command and refuse it, the same way the gate stops an unapproved commit.
If the written instruction proves not enough, that is the next step, rather than wording it more forcefully.

### One caveat on contents

A global `CLAUDE.md` gets committed and pushed like everything else here, so [Security](docs/security.md) applies to it in full.
It also invites machine specifics: absolute paths, host names, which drive holds what.
Keep it to preferences and conventions, and it stays portable to the next machine.

### What belongs here, and what belongs in a skill

Claude reads everything in this file at the start of every session in every project, whether or not the session touches the subject.
While it stays short that costs nothing.
A long guide would cost something every time, including in sessions that never write a word of prose.

A skill is the other half of the pair.
It installs to `~/.claude/skills/` and is available everywhere, like this file, but it loads only when the work matches its description.
So the choice is not where the instructions live, since both are global, but when they are paid for.

The test: instructions that must shape work nobody thought to ask about, such as a commit message, a code comment, or a reply in the session, have to be always on and belong here.
Instructions that matter only for a particular kind of task can be ten times longer as a skill and cost nothing the rest of the time.

Writing style is the worked example, not the whole of it.
Orwell's six rules apply to every sentence produced in any session, so they belong in this file.
A longer style guide, with examples, before and after pairs, and a checklist, would not, and would sit better as a `writing-style` skill that this file points at.

The same split applies to anything else that grows past a few lines: review checklists, commit message conventions, a house style for diagrams.
The test is the same each time, and [Split standing instructions between CLAUDE.md and skills](TODO.md#split-standing-instructions-between-claudemd-and-skills) records what is left to decide.

## Security

[docs/security.md](docs/security.md) covers what this repo keeps out of git, the gates that stop a secret before it is committed, and what GitHub checks on push.

## Open items

Work that is started and unfinished is in [TODO.md](TODO.md#open-items), along with [what else could live here](TODO.md#what-else-could-live-here).
