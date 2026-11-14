# TODO

What could come next, and the case for each.
Delete an item once it is done.

## Open items

Work that is started and unfinished, as opposed to [what else could live here](#what-else-could-live-here), which is speculative.
Each of these is known to be missing, not merely imagined.

### Merge `settings.json` instead of replacing it

Make the hooks easy to adopt for someone who keeps their own settings: [the hook scripts plan](docs/plans/hook-scripts.md).

### Split standing instructions between CLAUDE.md and skills

Described under [What belongs here, and what belongs in a skill](docs/standing-instructions.md#what-belongs-here-and-what-belongs-in-a-skill).

Nothing needs splitting while `CLAUDE.md` stays short and every entry in it earns being read every session.
The decision arrives when the first set of instructions outgrows that, and a full writing style guide is the likely first case, with review checklists, commit conventions, and diagram style queued behind it.

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

### Settle how spelling gets checked

Decide whether `cspell` runs only in the editor or also at commit beside `typos`: [the spelling plan](docs/plans/spelling.md).

### Set up a new machine

Install the tools the config assumes, check the result, and put the steps in one order: [the new-machine plan](docs/plans/new-machine.md).

### Turn on private vulnerability reporting

[SECURITY.md](SECURITY.md) tells a stranger to report through GitHub's private vulnerability reporting, which is off until someone turns it on.
No commit can do that; [repo-template's README](https://github.com/francisco-camargo/repo-template#use-it) has the command.

## What else could live here

Nothing below is set up yet.
This is the list of things worth pulling in as the need comes up, roughly in order of how much repetition each one removes.

### More Claude Code configuration

- **More skills:** anything done twice by hand is a candidate. Skills carry the *when* and *why* alongside the script, which is what makes them worth more than a loose shell script.
- **`~/.claude/agents/`:** subagent definitions, if a specialized reviewer or researcher proves worth the setup.
- **`~/.claude/commands/`:** custom slash commands for repeated multi-step workflows.
- **`~/.claude/keybindings.json`:** key bindings, which is the file nobody rebuilds from memory on a new machine.
- **More hooks:** the same `PreToolUse` mechanism as the gates above can auto-format after edits, block writes to protected paths, or log what ran. [Proposed hooks](#proposed-hooks) names specific ones.

### Proposed hooks

Block `pip install`, staging everything, and edits to installed copies, and name `--no-verify` in the commit prompt: [the proposed hooks plan](docs/plans/proposed-hooks.md).

### Shared repo scaffolding

The files every repo starts with live in [repo-template](https://github.com/francisco-camargo/repo-template), because they concern every project and not one person's machines.

### Global git config

`~/.gitconfig` on this machine carries an editor, a name, and an address.
`init.defaultBranch`, `pull.rebase`, aliases, `core.excludesFile`: all of it is re-derived per machine or lived without, which is the drift this repo exists to end.

Git also solves here what `settings.json` could not, because a gitconfig can include another one:

```ini
[include]
    path = ~/git/dotfiles/git/gitconfig
```

The install appends a line instead of replacing a file someone already owns, so the installer has nothing to ask about there.
Two more things fall out of the same mechanism.
`includeIf "gitdir:~/git/work/"` gives one set of repos its own address without a `hosts/` directory ([per-machine differences](#per-machine-differences)).
And `core.excludesFile` pointing here is what retires the `.gitignore` copied into every repo, above.

Identity and credentials come with it.
`user.email` should be GitHub's noreply address, which keeps the real one out of every commit.
And no `credential.helper store`: it writes the token to `~/.git-credentials` in plain text.
SSH keys, or the Git Credential Manager that Git for Windows sets up, keep the secret out of any file this repo could pick up.

Read [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) before the first commit of one: a credential helper and a remote URL with a token in it both live in this file.

### Machine setup

- **A bootstrap list** of what a machine needs, argued in [the new-machine plan](docs/plans/new-machine.md#install-what-this-config-already-assumes); it starts with the tools this repo's own config depends on.
- **Editor settings:** VS Code, covered on its own in [VS Code settings](#vs-code-settings) below.
- **Shell profile:** `.bashrc` for Git Bash, or the PowerShell profile, holding aliases and PATH tweaks. There is no `.bashrc` on this machine at all, and one line earns the file on its own: `export MSYS=winsymlinks:nativestrict` makes every `ln -s` in Git Bash behave the way `install.sh` has to force by hand ([Symlinks on Windows](docs/install.md#symlinks-on-windows)). GitHub's [ssh-agent auto-start block](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows) belongs there too, so a key loads once per session; the block goes in the repo, the key never does.
- **WSL config:** `/etc/wsl.conf` inside a distro and `.wslconfig` in the Windows home directory. A hand-edited `/etc/resolv.conf` reverts because WSL regenerates it at startup; `generateResolvConf = false` under `[network]` in `wsl.conf` keeps the edit.

### VS Code settings

This is the next thing to pull in, so it gets more than a bullet.

The files worth versioning all live in one directory (`%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux):

- `settings.json`, the bulk of it
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
Add keybindings once there are any worth keeping, and the extensions list once a second machine exists to replay it onto; that file is the one that pays off only on a fresh install.

One argument cuts the other way, and it is the new-machine one.
Redoing `settings.json` by hand takes a minute; rebuilding the extension set takes an afternoon, and what is missing from it only shows up when something stops working.
`code --list-extensions > vscode/extensions.txt` costs nothing to keep current, and it cannot drift the way `settings.json` does, because no UI writes back to it.
So take the extensions list first if the next machine is nearer than the next settings change.

Then pick a single source of truth, and let it be the repo.
This matters more for VS Code than it did for Claude Code, because `install.sh` is [copying rather than linking on this machine](docs/install.md#symlinks-on-windows), and VS Code has a settings UI that writes to `%APPDATA%` directly.
Editing settings through that UI while the repo holds the canonical copy produces two files that disagree, and the next `./install.sh` replaces the newer one with the repo's version.
The UI-edited file is not lost (`backup()` moves it into `backups/` first), but recovering a change from a backup in `%APPDATA%` is not a workflow anyone wants twice.
So: edit `vscode/settings.json` in the repo, commit, re-run `./install.sh`.
If a setting gets changed through the UI by reflex, and it will, copy it back into the repo before the next install, not after.

Enabling Developer Mode and getting real symlinks removes the whole problem, and is the single change that makes versioning editor settings pleasant instead of fiddly.
Worth doing first if you have the option.

Settings Sync is a rival source of truth.
If VS Code syncs settings through a GitHub account, Sync and a versioned `settings.json` overwrite each other.
Turn Sync off for settings when the repo takes over, or decide Sync is enough and drop this item.
Worth carrying over either way: the Dark+ theme, relative line numbers, and the Vim extension with its keybindings.

`install.sh` installs markdownlint's fallback rules as `~/.markdownlint.yaml`; carry the setting that points `markdownlint.configFile` at `${userHome}/.markdownlint.yaml`.
The extension uses a repo's own `.markdownlint.yaml` first, and falls back to `configFile` in a repo without one.
The path must exist on every machine, which `${userHome}` and the install make sure of; a path into one repo makes the extension fail in every other.
The `markdownlint.config` setting is deprecated.

Two things to expect.
VS Code settings collect absolute paths (`python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts that exist on one machine), and those are exactly what [Per-machine differences](#per-machine-differences) is about; strip or generalize them on the way in rather than committing a file that only works here.
And some extensions store tokens in `settings.json`, so read [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) before the first commit, not after.

### Per-machine differences

The moment a second machine has a genuinely different setting, the single-file approach strains.
The usual fix is a `hosts/<machine-name>/` directory that `install.sh` layers on top of the shared files after placing them, so shared config stays shared and only the differences are duplicated.
Worth doing when the need appears, not before.

### Check prose with Vale

Check the writing rules by machine, with Vale or a hook after Claude writes Markdown: [the prose checks plan](docs/plans/prose-checks.md).

### Point francisco-camargo's notes here

[francisco-camargo](https://github.com/francisco-camargo/francisco-camargo) keeps learning notes, and some of them describe setup this repo would own once the items above land: the ssh-agent block and git credentials in its git notes, VS Code settings in its VS Code notes, and the WSL fixes in its Linux notes.
As each lands here, replace the matching part of those notes with a link to this repo, so the steps live in one place.

### Before adding any of this

Shell profiles, git config, and bootstrap scripts are where credentials creep in: a remote URL with a token in it, an exported key in `.bashrc`.
Re-read [Security](docs/security.md) before pulling any of them in.
