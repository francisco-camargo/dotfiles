# TODO

What could come next, and the case for each.
Delete an item once it is done.

## Open items

Work that is started and unfinished, as opposed to [what else could live here](#what-else-could-live-here), which is speculative.
Each of these is known to be missing, not merely imagined.

### Merge `settings.json` instead of replacing it

Make the hooks easy to adopt for someone who keeps their own settings: [the hook scripts plan](docs/plans/hook-scripts.md).

### Split standing instructions between CLAUDE.md and skills

Move long instructions, such as a writing style guide, out of `CLAUDE.md` into skills once one outgrows it: [the standing instructions plan](docs/plans/standing-instructions-split.md).

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

Keep a shared gitconfig here and include it from `~/.gitconfig`: [the git config plan](docs/plans/git-config.md).

### Machine setup

- **A bootstrap list** of what a machine needs, argued in [the new-machine plan](docs/plans/new-machine.md#install-what-this-config-already-assumes); it starts with the tools this repo's own config depends on.
- **Editor settings:** VS Code, covered on its own in [the VS Code settings plan](docs/plans/vscode-settings.md).
- **Shell profile and WSL config:** [the shell and WSL plan](docs/plans/shell-and-wsl.md).

### VS Code settings

Version VS Code's settings, keybindings, and extensions list here: [the VS Code settings plan](docs/plans/vscode-settings.md).

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
