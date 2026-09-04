# dotfiles

Claude Code configuration, kept in one place so every machine behaves the same.

## Introduction

### What dotfiles are

Most programs store their settings as plain files in your home directory. On Unix
these traditionally start with a dot — `.bashrc`, `.gitconfig`, `.vimrc` — which
hides them from a normal `ls`. That is where the name *dotfiles* comes from.
`~/.claude/` is the same convention: the dot is on the directory, and
`settings.json` sits inside it.

### The problem they solve

Left alone, that config has three failure modes:

1. **It is scattered and untracked.** You change a setting, it works, and six
   months later you cannot recall what you changed or why. There is no `git log`
   for a home directory.
2. **It drifts between machines.** Laptop and desktop slowly diverge, and you
   only notice when something behaves differently on one of them.
3. **It is lost on reinstall.** A new machine means re-deriving everything from
   memory.

### The inversion

A dotfiles repo makes the git repo the real location and the home directory a set
of pointers. `~/.claude/settings.json` becomes a **symlink** — a file that is
really just a pointer to another path — aimed at `claude/settings.json` in this
repo. Both paths are then the same file: edit through either one and you have
edited the repo. Setting that up is all `install.sh` does.

The payoff is the ordinary git workflow applied to config:

- **One source of truth.** No hunting for which copy is the current one.
- **A history with reasons.** Every change is a commit, so `git log` answers "why
  is this set this way", and `git revert` undoes one that turned out badly.
- **Reproducible machines.** `git clone`, then `./install.sh`, and the machine
  behaves like the others. No hand-copying, no half-configured laptop.
- **Config that is readable.** The repo is also documentation. The sections below
  explain what each piece does, so the setup can be understood later rather than
  reverse-engineered.

### What is here today

Two things: `claude/settings.json`, holding the model choice and the three-layer
[git approval gate](#the-git-approval-gate), and the
[`md-to-pdf` skill](#the-md-to-pdf-skill). Small scope on purpose — it starts
with what actually gets used and grows when repetition justifies it.
[What else could live here](#what-else-could-live-here) lists the likely
additions.

### The working loop

Edit a file in this repo, commit it, and on any other machine `git pull`. With
symlinks the change is live immediately.

On this Windows machine it is not, because Developer Mode is off and `install.sh`
falls back to copying — and copies do not track edits. Until that changes, re-run
`./install.sh` after editing anything here, or the change stays in the repo and
never reaches `~/.claude/`. Details in [Symlinks on Windows](#symlinks-on-windows).

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
copies instead.

As of this writing that fallback is what happens on the main Windows machine —
Developer Mode is off, so `install.sh` copies. Copies work fine, but they do not
track edits: after changing anything in this repo, re-run `./install.sh` to push
the change back out. Turn Developer Mode on and you get real symlinks, and edits
propagate on their own.

### Settings only load at startup

Claude Code reads `~/.claude/settings.json` when a session starts. Installing or
editing settings mid-session does nothing until the config reloads — a session
that was already running keeps the old rules, including no git approval gate.
Restart Claude Code, or open `/hooks` once, before assuming a change is live.

To confirm the gate is actually working, ask Claude to make a trivial commit. You
should get an approval prompt. If the commit just goes through, the settings have
not reloaded yet.

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

### Skill scope, and duplicates

A skill installed here lands in `~/.claude/skills/` and is available in every
project. A skill committed to a repo's own `.claude/skills/` is available only in
that repo. When the same skill name exists in both, the project copy wins.

`md-to-pdf` currently exists in both places — here, and in
`gb-roles-and-responsibilities/.claude/skills/`. The copies are identical so
nothing misbehaves, but there are two sources of truth. Worth deleting the
project copy at some point and letting this repo own it.

## What else could live here

Nothing below is set up yet. This is the list of things worth pulling in as the
need comes up, roughly in order of how much repetition each one removes.

### More Claude Code configuration

- **`~/.claude/CLAUDE.md`** — standing instructions that apply to every project:
  house style, how you like commits written, tools to prefer or avoid. The
  natural home for preferences that keep having to be re-explained.
- **More skills** — anything done twice by hand is a candidate. Skills carry the
  *when* and *why* alongside the script, which is what makes them worth more than
  a loose shell script.
- **`~/.claude/agents/`** — subagent definitions, if a specialized reviewer or
  researcher earns its keep.
- **`~/.claude/commands/`** — custom slash commands for repeated multi-step
  workflows.
- **More hooks** — the same `PreToolUse` mechanism as the git gate can auto-format
  after edits, block writes to protected paths, or log what ran.

### Shared repo scaffolding

The gym repos already repeat the same files by hand. `.gitignore` is in all
three; `.gitattributes` with `* text=auto eol=lf` is in two and had to be written
twice; `cspell.json` exists in one and will want to exist in the others.

Two ways to stop copying them around:

- **Templates here** plus a small `new-repo.sh` that stamps them into a fresh
  repo. Simple, and each repo stays self-contained.
- **Global git config** — `core.attributesFile` and `core.excludesFile` point at
  files in this repo, so the rules apply everywhere without any per-repo file.
  Nothing to copy, but the rules become invisible to anyone cloning a repo, which
  matters if the repos are ever shared.

Global git config also carries aliases, `pull.rebase`, `init.defaultBranch`, and
the default commit editor.

### Machine setup

- **A bootstrap script** listing what a machine needs — `winget install` or
  `scoop install` lines for gh, Git, VS Code, a PDF viewer. Turns "set up a new
  laptop" into one command.
- **Editor settings** — VS Code `settings.json`, `keybindings.json`, and an
  extensions list, which `code --install-extension` can replay from a file.
- **Shell profile** — `.bashrc` for Git Bash, or the PowerShell profile, holding
  aliases and PATH tweaks.

### Per-machine differences

The moment a second machine has a genuinely different setting, the single-file
approach strains. The usual fix is a `hosts/<machine-name>/` directory that
`install.sh` layers on top of the shared files after placing them, so shared
config stays shared and only the differences are duplicated. Worth doing when the
need actually appears, not before.

### What not to put here

The repo is private, but private is not the same as safe — it gets cloned to
every machine and shows up in plain text in every backup. Keep out API keys,
tokens, `~/.ssh/` private keys, `.env` files, and anything with a password in it.
`.gitignore` already excludes `*.bak` files, which is where `install.sh` parks
whatever it replaced. If a config file needs a secret, keep the secret in an
environment variable and commit only the reference to it.
