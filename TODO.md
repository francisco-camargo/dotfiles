# TODO

What could come next, and the case for each.
Delete an item once it is done.

## Open items

Work that is started and unfinished, as opposed to [what else could live here](#what-else-could-live-here), which is speculative.
Each of these is known to be missing, not merely imagined.

### Ask before replacing a file

`install.sh` replaces whatever it finds, and the only notice is a "backing up existing" line as it goes.
Nothing is deleted, but someone's `settings.json`, their own `CLAUDE.md`, or a skill edited in place ends up in `~/.claude/backups/`, and nothing says how to put it back.
Nobody who runs this script should lose what was on their machine without being asked.

For each file the installer places:

| What is at the destination | What happens |
| --- | --- |
| Nothing, the same content, or a link into this repo | Place it without asking |
| Anything else | Show what is there, and ask |

The question offers:

- **keep** the existing file and skip this one, which is the default
- **replace** it, backing it up as today and printing the command that restores the backup
- **diff** the two, then ask again
- **quit**, leaving the rest untouched

With no terminal to ask on, as when piped or run from another script, the answer is keep.
Replacing without a terminal takes an explicit `--replace-existing`.

Keeping `settings.json` means going without the hooks, so the installer says so and prints the block to paste in by hand.

This one change covers three problems that were tracked apart:

- **`settings.json` replaced wholesale** ([the warning](README.md#installsh-replaces-settingsjson-wholesale)): a settings file someone already has stays unless they choose otherwise.
- **Copy-mode drift** ([copies drift both ways](README.md#copies-drift-both-ways)): a skill edited in place under `~/.claude` differs from the repo, so the next install asks instead of overwriting it.
- **Writing before showing**: the question is the preview, so a bare `./install.sh` cannot change a file before its owner has seen what it would do, and `--dry-run` stops being something to know about in advance.

Whether a destination matches the repo is the same check [the doctor script](#verify-the-machine-not-only-write-to-it) needs, so it should be written once.

The limit is the one that applies to everything here: the script should stay readable in a single sitting.
A question and a comparison fit that.
An `--undo` or a separate plan-then-apply mode would not, and asking first makes both less needed.

### Merge `settings.json` instead of replacing it

Described in full under [`install.sh` replaces `settings.json` wholesale](README.md#installsh-replaces-settingsjson-wholesale).
[Ask before replacing a file](#ask-before-replacing-a-file) stops the installer taking someone's settings without asking.
What is left is making the hooks easy to adopt for someone who keeps their own.

A real merge is the wrong fix.
It needs a JSON parser, and the rule that keeps the hooks portable — `sed` and `grep` only, no `jq`, no `node`, no `python` — is the same rule that makes merging JSON inside `install.sh` a bad idea.
A merger written in awk would fail quietly on a nested key, which is the failure this repo keeps trying to design out.

Two smaller pieces instead:

- **Hand other people the project-level route.** Hook entries merge across settings levels rather than replacing each other, so the gates work committed to a shared project's `.claude/settings.json`. Everyone who clones that repo gets the gates, and no home directory is touched.
- **Move the hook bodies into scripts.** `claude/hooks/git-gate.sh`, `claude/hooks/sed-gate.sh`, and `claude/hooks/uv-gate.sh`, with `settings.json` holding stanzas that call them. It does not fix the merge, but it shrinks the block a person has to paste and makes each hook testable on its own rather than by pulling a string back out of JSON — which the uv gate's escaping already argues for.

### Split standing instructions between CLAUDE.md and skills

Described under [What belongs here, and what belongs in a skill](README.md#what-belongs-here-and-what-belongs-in-a-skill).

Nothing is wrong today.
`CLAUDE.md` is short and every entry in it earns being read every session.
The decision arrives when the first set of instructions outgrows that, and a full writing style guide is the likely first case — with review checklists, commit conventions, and diagram style queued behind it.

Three things to settle when it does:

- Where the line falls: a short core here, the long form in a skill, and this file pointing at it.
- Whether a skill's `description` can trigger reliably for prose work, which is a vaguer trigger than "render this Markdown to PDF".
- Whether the split runs per subject, or one `house-style` skill covers all of it.

### Prune `~/.claude/backups/`

Every install adds a copy of whatever it replaced and nothing removes the old ones.
Harmless while the tree is small, and worth a `--keep N` or a date cutoff before the directory turns into somewhere nobody looks.

### Delete the duplicate `md-to-pdf`

Another repo keeps its own copy of the `md-to-pdf` skill.
Delete that copy and let this repo own the skill, as [Skill scope, and duplicates](README.md#skill-scope-and-duplicates) says to.

### Consolidate the two pre-commit configs

The config here is not the only one I maintain.
[`francisco-camargo/francisco-camargo`](https://github.com/francisco-camargo/francisco-camargo/blob/master/src/python/pre-commit/.pre-commit-config.yaml) carries a fuller one for Python work, and the two were written without reference to each other.

They agree on the part that matters least and differ on the part that matters most.
Both pin `pre-commit/pre-commit-hooks` at the same revision and share most of its hygiene hooks.
Then each is missing what the other has where it counts: `gitleaks` runs only here, though the Python config is the one sitting in front of dependency files and API clients, and `codespell` runs only there, though this repo is mostly prose.

Three layers, once they are pulled apart:

- **Wanted everywhere, language-agnostic.** The hygiene hooks, `detect-private-key`, `check-shebang-scripts-are-executable`, `gitleaks`, `codespell`.
- **Python only.** `black`, `flake8`, `isort`, `mypy`, `bandit`, `interrogate`, `pip-audit`, `add-trailing-comma`.
- **Repo-specific, at first.** The link check, `lychee`, added for this repo and now also in [repo-template](https://github.com/francisco-camargo/repo-template).

While the two are side by side, the cheap question is what each is missing.
`check-json` and `check-toml` are in the Python config and not here; `codespell` would have caught more than one wobble in this README; `mixed-line-ending` overlaps what `.gitattributes` already does, so it may be redundant rather than missing.

The obstacle is that `pre-commit` has no include or extends.
One config cannot inherit another, so sharing a base means choosing between a block documented in one place and copied by hand — the drift this repo exists to end — and generating the file, which trades the drift for a build step.
Worth settling before a third config turns up and makes the same choice a third time.

### Settle how spelling gets checked

`cspell.json` sits in the repo root and the VS Code extension finds it without being told to, so a misspelling is underlined as I type it.
Nothing checks spelling when a commit is created, and nothing checks it at all for anyone who does not run that extension.

Two tools could close that, and they work differently.
`codespell` carries a list of known misspellings and flags only those, which keeps it quiet and spares it a word list.
`cspell` works from dictionaries and flags anything absent from them, which is stricter and is why the word list in `cspell.json` had to be written before it was usable here.

`codespell` is the cheaper of the two.
It is a Python tool, `pre-commit` is itself a Python tool on this machine, and the Python config runs it, so [consolidating the two configs](#consolidate-the-two-pre-commit-configs) brings it here as part of a job already on this list.

`cspell` costs a second runtime.
Its hook is `language: node`, so `pre-commit` builds that environment by fetching a node runtime into `~/.cache/pre-commit`, the way it already fetches the Go toolchain for `gitleaks`.
Nothing has to be installed on the machine for that, and the environment is reusable once built: `pre-commit run cspell --all-files` then runs the checker on demand, which is the only way anything here runs `cspell` outside the editor.
That last part is what the word list is waiting on — it was written by reading the repo and judging what the dictionaries already cover, and no run has confirmed it.

Running both means two lists of exceptions that drift apart, because each tool has to be told its own.
The order worth trying: take `codespell` with the config consolidation, leave `cspell` as an editor underline, and add the `cspell` hook only if a misspelling gets past `codespell` or the word list turns out to need checking.

### Install what this config already assumes

The [uv gate](README.md#the-uv-gate) refuses a bare `python` and tells Claude to run `uv` instead, and the [commit gates](docs/security.md#the-commit-gates) need `pre-commit`.
A new machine has neither.
So the first session after an install meets a hook demanding a tool that is not there, and `install.sh` ends by announcing that the gates are off — the repo naming a hole it could fill.

What closes it is a list of what a machine needs, kept as a file rather than a run of install lines: git, `gh`, `uv`, `pre-commit`, VS Code.
`winget export` writes that list from a machine that already works and `winget import` replays it, which keeps it a file you can read and diff rather than a script you have to run to find out what it does — the same reason the VS Code extensions list below is a file.

It stays separate from `install.sh`.
Installing tools onto a machine is a larger claim than placing config files, and making it a side effect of the second is the trade `install.sh` already refuses when it declines to install `pre-commit` for you.

### Verify the machine, not only write to it

`install.sh` places files and reports what it did.
Nothing answers the question that comes next on a new machine: is this right yet?
Today you answer it by reading this README and checking by hand.

A `doctor.sh` would report state and change nothing:

- link or copy, for each installed target
- whether Developer Mode is on
- which installed copies differ from the repo
- whether this clone has a `pre-commit` hook in `.git/hooks/`
- whether `uv` and `gh` are on PATH

Two of those are worth more than a status line.
The difference check is the detecting half of [asking before replacing a file](#ask-before-replacing-a-file), so building it once serves both.
And a doctor script is where the test that [Hooks](README.md#hooks) demands can live: pull each pattern back out of `settings.json`, feed it a sample tool payload, and confirm it still matches.
A gate that quietly stopped firing is the failure this repo keeps designing against, and nothing checks for it.

`sed` and `grep` only, for the reason the hooks are.

### Put the new-machine steps in one order

The steps are all written down and none of them are together.
Developer Mode opens [Install on a new machine](README.md#install-on-a-new-machine), `pre-commit` arrives in `install.sh`'s closing warning, restarting Claude Code is the line after the install command, and authenticating to GitHub is nowhere, because cloning is where the instructions start.
Someone setting up a machine wants the sequence once, in one place:

1. Developer Mode, first, because it decides whether the install links or copies
2. git, and the tools the config assumes
3. authentication — `gh auth login`, or an SSH key
4. clone, `./install.sh --dry-run`, then `./install.sh`
5. restart Claude Code

Each step already has a section arguing it.
The list is a table of contents for one afternoon, not a replacement for them.

### Add a SECURITY.md

GitHub treats a `SECURITY.md` in the root, `docs/` or `.github/` as the repo's security policy.
It appears under Security and quality → Security policy, and GitHub points to it when someone opens an issue.
Its job is to tell a stranger how to report a vulnerability without posting it in public.

This repo needs one because [it runs code on every machine that installs it](docs/security.md#this-repo-runs-code-on-every-machine-that-installs-it): the hooks run on every tool call, and anyone who finds a way to abuse that should be able to tell the owner privately.

- **Where:** the root. `docs/SECURITY.md` would clash with `docs/security.md` on Windows and macOS, whose filesystems ignore case.
- **What it says:** report through GitHub's private vulnerability reporting, expect no support promise for personal config, and read [docs/security.md](docs/security.md) for how the repo keeps secrets out.
- **The switch:** private vulnerability reporting is off by default, under Settings → Advanced Security. No commit can turn it on.

## What else could live here

Nothing below is set up yet.
This is the list of things worth pulling in as the need comes up, roughly in order of how much repetition each one removes.

### More Claude Code configuration

- **More skills** — anything done twice by hand is a candidate. Skills carry the *when* and *why* alongside the script, which is what makes them worth more than a loose shell script.
- **`~/.claude/agents/`** — subagent definitions, if a specialized reviewer or researcher proves worth the setup.
- **`~/.claude/commands/`** — custom slash commands for repeated multi-step workflows.
- **`~/.claude/keybindings.json`** — key bindings, which is the file nobody rebuilds from memory on a new machine.
- **More hooks** — the same `PreToolUse` mechanism as the gates above can auto-format after edits, block writes to protected paths, or log what ran.

### Shared repo scaffolding

The files every repo starts with live in [repo-template](https://github.com/francisco-camargo/repo-template), because they concern every project and not one person's machines.

### Global git config

`~/.gitconfig` on this machine carries an editor, a name, and an address.
`init.defaultBranch`, `pull.rebase`, aliases, `core.excludesFile` — all of it is re-derived per machine or lived without, which is the drift this repo exists to end.

Git also solves here what `settings.json` could not, because a gitconfig can include another one:

```ini
[include]
    path = ~/git/dotfiles/git/gitconfig
```

The install appends a line instead of replacing a file someone already owns, so [asking before replacing a file](TODO.md#ask-before-replacing-a-file) has nothing to ask about there.
Two more things fall out of the same mechanism.
`includeIf "gitdir:~/git/work/"` gives one set of repos its own address without a `hosts/` directory ([per-machine differences](#per-machine-differences)).
And `core.excludesFile` pointing here is what retires the `.gitignore` copied into every repo, above.

Identity and credentials come with it.
`user.email` should be GitHub's noreply address, which keeps the real one out of every commit.
And no `credential.helper store`: it writes the token to `~/.git-credentials` in plain text.
SSH keys, or the Git Credential Manager that Git for Windows sets up, keep the secret out of any file this repo could pick up.

Read [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) before the first commit of one: a credential helper and a remote URL with a token in it both live in this file.

### Machine setup

- **A bootstrap list** of what a machine needs, argued under [Install what this config already assumes](TODO.md#install-what-this-config-already-assumes) — it starts with the tools this repo's own config depends on.
- **Editor settings** — VS Code, covered on its own in [VS Code settings](#vs-code-settings) below.
- **Shell profile** — `.bashrc` for Git Bash, or the PowerShell profile, holding aliases and PATH tweaks. There is no `.bashrc` on this machine at all, and one line earns the file on its own: `export MSYS=winsymlinks:nativestrict` makes every `ln -s` in Git Bash behave the way `install.sh` has to force by hand ([Symlinks on Windows](README.md#symlinks-on-windows)). GitHub's [ssh-agent auto-start block](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows) belongs there too, so a key loads once per session; the block goes in the repo, the key never does.
- **WSL config** — `/etc/wsl.conf` inside a distro and `.wslconfig` in the Windows home directory. A hand-edited `/etc/resolv.conf` reverts because WSL regenerates it at startup; `generateResolvConf = false` under `[network]` in `wsl.conf` keeps the edit.

### VS Code settings

This is the next thing to pull in, so it gets more than a bullet.

The files worth versioning all live in one directory — `%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux:

- `settings.json` — the bulk of it
- `keybindings.json`
- an extensions list, produced by `code --list-extensions > vscode/extensions.txt` and replayed by looping `code --install-extension` over the file

The first two are ordinary `place()` targets and need only a second destination in `install.sh`, since VS Code does not live under `$HOME`:

```sh
vsdest="${VSCODE_USER_DIR:-$APPDATA/Code/User}"
place "$repo/vscode/settings.json"    "$vsdest/settings.json"
place "$repo/vscode/keybindings.json" "$vsdest/keybindings.json"
```

`$APPDATA` is set inside Git Bash.
The extensions list is the odd one out: it is a script input rather than a symlink target, so it wants its own small `vscode/install-extensions.sh`.

#### The recommendation

Start with `settings.json` alone.
Add keybindings once there are any worth keeping, and the extensions list once a second machine exists to replay it onto — that file is the one that pays off only on a fresh install.

One argument cuts the other way, and it is the new-machine one.
Redoing `settings.json` by hand takes a minute; rebuilding the extension set takes an afternoon, and what is missing from it only shows up when something stops working.
`code --list-extensions > vscode/extensions.txt` costs nothing to keep current, and it cannot drift the way `settings.json` does, because no UI writes back to it.
So take the extensions list first if the next machine is nearer than the next settings change.

Then pick a single source of truth, and let it be the repo.
This matters more for VS Code than it did for Claude Code, because `install.sh` is [copying rather than linking on this machine](README.md#symlinks-on-windows), and VS Code has a settings UI that writes to `%APPDATA%` directly.
Editing settings through that UI while the repo holds the canonical copy produces two files that disagree, and the next `./install.sh` replaces the newer one with the repo's version.
The UI-edited file is not lost — `backup()` moves it into `backups/` first — but recovering a change from a backup in `%APPDATA%` is not a workflow anyone wants twice.
So: edit `vscode/settings.json` in the repo, commit, re-run `./install.sh`.
If a setting gets changed through the UI by reflex — and it will — copy it back into the repo before the next install, not after.

Enabling Developer Mode and getting real symlinks removes the whole problem, and is the single change that makes versioning editor settings pleasant instead of fiddly.
Worth doing first if you have the option.

Settings Sync is a rival source of truth.
If VS Code syncs settings through a GitHub account, Sync and a versioned `settings.json` overwrite each other.
Turn Sync off for settings when the repo takes over, or decide Sync is enough and drop this item.
Worth carrying over either way: the Dark+ theme, relative line numbers, and the Vim extension with its keybindings.

Two things to expect.
VS Code settings collect absolute paths — `python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts that exist on one machine — and those are exactly what [Per-machine differences](#per-machine-differences) is about; strip or generalize them on the way in rather than committing a file that only works here.
And some extensions store tokens in `settings.json`, so read [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) before the first commit, not after.

### Per-machine differences

The moment a second machine has a genuinely different setting, the single-file approach strains.
The usual fix is a `hosts/<machine-name>/` directory that `install.sh` layers on top of the shared files after placing them, so shared config stays shared and only the differences are duplicated.
Worth doing when the need actually appears, not before.

### Point francisco-camargo's notes here

[francisco-camargo](https://github.com/francisco-camargo/francisco-camargo) keeps learning notes, and some of them describe setup this repo would own once the items above land: the ssh-agent block and git credentials in its git notes, VS Code settings in its VS Code notes, and the WSL fixes in its Linux notes.
As each lands here, replace the matching part of those notes with a link to this repo, so the steps live in one place.


### Before adding any of this

Shell profiles, git config, and bootstrap scripts are where credentials actually creep in — a remote URL with a token in it, an exported key in `.bashrc`.
Re-read [Security](docs/security.md) before pulling any of them in.
