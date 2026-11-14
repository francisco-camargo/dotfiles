# TODO

The work ahead, in priority order.
Each item is one line; an item that needs more has a plan in [docs/plans/](docs/plans/).
Delete an item once it is done, along with its plan.

## Next

- [Markdown audit skill](docs/plans/markdown-audit.md): audit a repo's Markdown against its pre-commit hooks, its writing rules, and an opinion on how its files fit together.
- [New-machine setup](docs/plans/new-machine.md): install the tools the config assumes, check the result, and put the steps in one order.
- [VS Code settings](docs/plans/vscode-settings.md): version VS Code's settings, keybindings, and extensions list here.
- [Uninstall](docs/plans/uninstall.md): `./install.sh --uninstall` removes what the install placed and leaves anything that differs.

## Small tasks

- Turn on private vulnerability reporting, which [SECURITY.md](SECURITY.md) sends reports through; [repo-template's README](https://github.com/francisco-camargo/repo-template#use-it) has the command.
- Delete the copy of `md-to-pdf` another repo keeps, as [Skill scope, and duplicates](README.md#skill-scope-and-duplicates) says to.
- As each item lands, replace the matching part of [francisco-camargo](https://github.com/francisco-camargo/francisco-camargo)'s notes with a link here: the ssh-agent block and git credentials, VS Code settings, and the WSL fixes.

## Later

- [Hook scripts](docs/plans/hook-scripts.md): make the gates easy to adopt for someone who keeps their own `settings.json`.
- [Proposed hooks](docs/plans/proposed-hooks.md): block `pip install`, staging everything, and edits to installed copies, and name `--no-verify` in the commit prompt.
- [Prose checks](docs/plans/prose-checks.md): check the writing rules by machine, with Vale or a hook after Claude writes Markdown.
- [Spelling](docs/plans/spelling.md): decide whether `cspell` runs only in the editor or also at commit beside `typos`.
- [Git config](docs/plans/git-config.md): keep a shared gitconfig here and include it from `~/.gitconfig`.
- [Shell profile and WSL config](docs/plans/shell-and-wsl.md): a `.bashrc` that sets `MSYS` and starts ssh-agent, and the WSL settings that survive a restart.
- [Standing instructions split](docs/plans/standing-instructions-split.md): move long instructions out of `CLAUDE.md` into skills once one outgrows it.

## Ideas

Nothing here is planned; pull an item in when the need comes up.

- **More skills:** anything done twice by hand is a candidate. Skills carry the *when* and *why* alongside the script, which is what makes them worth more than a loose shell script.
- **`~/.claude/agents/`:** subagent definitions, if a specialized reviewer or researcher proves worth the setup.
- **`~/.claude/commands/`:** custom slash commands for repeated multi-step workflows.
- **`~/.claude/keybindings.json`:** key bindings, which is the file nobody rebuilds from memory on a new machine.
- **More hooks:** the same `PreToolUse` mechanism as the [gates](docs/hooks.md) can auto-format after edits, block writes to protected paths, or log what ran.
- **Per-machine differences:** once a second machine needs a different setting, a `hosts/<machine-name>/` directory that `install.sh` lays over the shared files, so only the differences are duplicated.

## Before adding shell or git config

Shell profiles, git config, and bootstrap scripts are where credentials creep in: a remote URL with a token in it, an exported key in `.bashrc`.
Re-read [Security](docs/security.md) before pulling any of them in.
