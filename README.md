# dotfiles

Configuration files kept in one place so every machine behaves the same.

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

## Platform support

`bash` and `git` are the only requirements. There is nothing here that ties the
repo to one operating system:

- **macOS and Linux** work as-is, and get real symlinks by default — no
  Developer Mode step, so the [working loop](#the-working-loop) above is the
  live-edit one rather than the re-run-`install.sh` one.
- **Windows** works through Git Bash. `.gitattributes` normalizes line endings
  to LF so the scripts stay executable everywhere.

The Windows-specific pieces are inert elsewhere rather than broken: the
`PowerShell(...)` entries in `permissions.ask` name a tool that does not exist on
macOS, `md2pdf.sh` guards its `cygpath` calls behind `command -v`, and its
browser search list already includes the `/Applications/` paths alongside the
`C:\Program Files\` ones.

Where the sections below say "this Windows machine", they are reporting where
the config happens to run today, not stating a requirement.

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

## Security

The repo is private, but private is not the same as safe. It gets cloned to every
machine, sits in plain text in every backup, and is readable by anything running
as you. Treat it as a file that leaks eventually and decide what goes in it on
that basis.

### What is in here today

Nothing sensitive. `settings.json` holds a model name and permission rules,
`install.sh` holds paths, the skill is shell, awk, and CSS. Searching the entire
history — not just the current files — for key, token, and password patterns
turns up only this README talking about them. That is the state to preserve, and
it is worth re-checking whenever the repo grows.

### The directory this installs into is full of secrets

This is the real hazard, and it is not obvious. `~/.claude/` contains far more
than `settings.json`:

| Path | What it holds |
| --- | --- |
| `~/.claude/.credentials.json` | The Claude Code auth token |
| `~/.claude.json` | OAuth account, user and machine IDs, per-project history |
| `~/.claude/projects/` | Full transcripts of every session, in every repo |
| `~/.claude/shell-snapshots/`, `session-env/` | Captured shell state, including exported environment variables |
| `~/.claude/file-history/`, `backups/` | Copies of files as they were edited during sessions |

None of that belongs in git. Transcripts alone are the whole content of private
repos plus anything read or pasted during a session.

The failure mode is not typing a password into `settings.json` — nobody does
that. It is broadening `install.sh` to sync "all of `~/.claude`" and sweeping the
rest up with it. So: **the install stays an explicit allowlist**. `install.sh`
names each file it places, one `place` line at a time, and never walks the
directory. Adding config means adding a line, not widening a glob.

### Commit the reference, not the secret

`settings.json` supports an `env` block, which is exactly where someone would
paste an `ANTHROPIC_API_KEY` to make something work. Don't. Set the variable in
the shell profile or the OS environment and let the config refer to it by name.
The same rule covers every future addition: API keys, tokens, `~/.ssh/` private
keys, `.env` files, anything with a password in it.

`.gitignore` already excludes `*.bak`, which is where `install.sh` parks whatever
it replaced — those backups are copies of real local config and should never be
committed.

### Git history does not forget

If a secret is ever committed, deleting it in a later commit does not remove it.
It stays in every clone, in every fork, and on GitHub's servers. The fix, in
order:

1. **Rotate the credential.** Assume it is burned. This is the step that actually
   matters.
2. Rewrite the history with `git filter-repo` and force-push, as cleanup.

Same reason to audit the full history rather than the working tree before ever
flipping this repo public — going public publishes every commit ever made, not
the current state.

### This repo runs code on every machine that installs it

`install.sh` is a script you execute. More significantly, the `PreToolUse` hook
in `settings.json` runs a shell command on *every* Bash and PowerShell tool call
on every machine that has installed it. Whatever lands in this repo, runs.

That makes write access to this repo equivalent to code execution on all your
machines:

- Keep 2FA on the GitHub account.
- Read the diff before `git pull && ./install.sh` on another machine, the same
  way you would for any script handed to you.
- If this repo is ever shared or made public, treat a pull request against it as
  a change to a security-sensitive script, not a config tweak.

### A guardrail, if it earns its keep

A pre-commit hook running `gitleaks` or `trufflehog` blocks the accidental
commit before it happens. Overkill at the current size — there is nothing here to
catch. Worth adding once the repo grows to shell profiles and git config, which
is where credentials genuinely creep in: a remote URL with a token embedded in
it, an alias carrying a password, an exported key in `.bashrc`.

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
- **Editor settings** — VS Code, covered on its own in
  [VS Code settings](#vs-code-settings) below.
- **Shell profile** — `.bashrc` for Git Bash, or the PowerShell profile, holding
  aliases and PATH tweaks.

### VS Code settings

This is the next thing to pull in, so it gets more than a bullet.

The three files worth versioning all live in one directory —
`%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on
macOS, `~/.config/Code/User` on Linux:

- `settings.json` — the bulk of it
- `keybindings.json`
- an extensions list, produced by `code --list-extensions > vscode/extensions.txt`
  and replayed by looping `code --install-extension` over the file

The first two are ordinary `place()` targets and need only a second destination
in `install.sh`, since VS Code does not live under `$HOME`:

```sh
vsdest="${VSCODE_USER_DIR:-$APPDATA/Code/User}"
place "$repo/vscode/settings.json"    "$vsdest/settings.json"
place "$repo/vscode/keybindings.json" "$vsdest/keybindings.json"
```

`$APPDATA` is set inside Git Bash. The extensions list is the odd one out: it is
a script input rather than a symlink target, so it wants its own small
`vscode/install-extensions.sh`.

#### The recommendation

Start with `settings.json` alone. Add keybindings once there are any worth
keeping, and the extensions list once a second machine exists to replay it onto —
that file is the one that pays off only on a fresh install.

Then pick a single source of truth, and let it be the repo. This matters more for
VS Code than it did for Claude Code, because `install.sh` is
[copying rather than linking on this machine](#symlinks-on-windows), and VS Code
has a settings UI that writes to `%APPDATA%` directly. Editing settings through
that UI while the repo holds the canonical copy produces two files that disagree,
and the next `./install.sh` replaces the newer one with the repo's version. The
UI-edited file is not lost — `backup()` moves it to
`settings.json.bak.<timestamp>` first — but recovering a change from a timestamped
backup in `%APPDATA%` is not a workflow anyone wants twice. So: edit
`vscode/settings.json` in the repo, commit, re-run `./install.sh`. If a setting
gets changed through the UI by reflex — and it will — copy it back into the repo
before the next install rather than after.

Enabling Developer Mode and getting real symlinks removes the whole problem, and
is the single change that makes versioning editor settings pleasant instead of
fiddly. Worth doing first if you have the option.

Two things to expect. VS Code settings collect absolute paths —
`python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts
that exist on one machine — and those are exactly what
[Per-machine differences](#per-machine-differences) is about; strip or generalize
them on the way in rather than committing a file that only works here. And some
extensions store tokens in `settings.json`, so read
[Commit the reference, not the secret](#commit-the-reference-not-the-secret)
before the first commit, not after.

### Per-machine differences

The moment a second machine has a genuinely different setting, the single-file
approach strains. The usual fix is a `hosts/<machine-name>/` directory that
`install.sh` layers on top of the shared files after placing them, so shared
config stays shared and only the differences are duplicated. Worth doing when the
need actually appears, not before.


### Before adding any of this

Shell profiles, git config, and bootstrap scripts are where credentials actually
creep in — a remote URL with a token in it, an exported key in `.bashrc`. Re-read
[Security](#security) before pulling any of them in.
