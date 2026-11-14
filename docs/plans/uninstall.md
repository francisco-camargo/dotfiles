# Plan: uninstall

## Goal

`./install.sh --uninstall` removes each file and link `install.sh` placed, and undoes the git template setting it made, leaving alone anything that differs from the repo's copy.

## Why

Trying this config on a machine, or handing a machine back, should not mean finding and deleting each path by hand.

## One list of targets

The install names each target in its own `place` line.
An uninstall that kept a second list would drift from the first as plans like [VS Code settings](vscode-settings.md) and [Shell profile and WSL config](shell-and-wsl.md) add targets.

So the targets move into one list of `src target` pairs, and both the install loop and the uninstall loop read it.
A target added later gets an uninstall with no extra work.

## What counts as installed

The uninstall removes a target only when it holds nothing of the user's:

- a link to this repo's file, as `linked()` tests, or
- a plain copy that matches this repo's file, as `same_copy()` tests.

Anything else at the target stays, with a line saying why: a copy edited under `~/.claude`, a link to somewhere else, or a file the user kept when the install asked.
This follows the install's rule that nothing of the user's goes without being asked.

A target that does not exist is skipped without comment.

## Backups

The uninstall does not restore from `~/.claude/backups/`, and deletes none of it.
For each target it removes, it prints the newest backup of that name, if there is one, with the `mv` command to restore it.

## Git setup

- `init.templateDir`: unset it only when it is `~/.git-template`, the value `install.sh` writes; any other value was the user's and stays.
- `~/.git-template/hooks/pre-commit`: delete it, then delete `~/.git-template` if that leaves it empty.
- Repos cloned since the install keep the hook git copied into them; the uninstall says so rather than walking the disk for them.
- This clone's own `pre-commit install` stays: it guards commits to this repo, which outlive the uninstall.

## Options

- `--dry-run` with `--uninstall` prints what it would remove and removes nothing, through `run`.
- `--copy`, `--replace-existing`, and `--keep` mean nothing to an uninstall; combined with `--uninstall` they exit with status 2, like an unknown option.
- `CLAUDE_HOME` set skips the git steps, as it does for the install, so the tests never touch the real global config.

## Steps

- [ ] Move the `place` lines into one list of targets that the install loops over, with no change in behaviour; `tests/install-test.sh` passes before and after.
- [ ] Add `--uninstall` for the targets in the list, with tests written first: removes a link to the repo and a matching copy, keeps an edited copy and a foreign link, prints the newest backup's restore command, removes nothing under `--dry-run`, rejects `--copy` and `--keep` beside it.
- [ ] Undo the git template setup under `--uninstall`, with tests written first: unsets `init.templateDir` only when it is `~/.git-template`, removes the hook and the empty directory, skips both when `CLAUDE_HOME` is set.

## Docs to update

- [ ] `install.sh` header: a usage line for `--uninstall`, which `--help` prints; keep the line about backups last, or update the `--help prints the whole header` test.
- [ ] `docs/install.md`: an `## Uninstall` section after "What the installer does", saying what goes, what stays and why, and that existing clones keep their hook.
- [ ] `README.md`, under "Install on a new machine": one line pointing to the uninstall section.
- [ ] `docs/plans/git-config.md`: a step to remove the `[include]` under `--uninstall`, since it edits `~/.gitconfig` rather than placing a target.

## Updates to send

None.

## Open questions

- Should the uninstall offer to restore the newest backup, rather than print the command? I lean no: that backup may be an older copy of this repo's file rather than the user's own, and the script cannot tell which.
- Should it remove the `pre-commit` hook from this clone too? I lean no: the gates protect commits to this repo whether or not the config is installed.

## Done when

`tests/install-test.sh` passes, and on a scratch home `./install.sh` followed by `./install.sh --uninstall` leaves the home as it was before the install, apart from `~/.claude/backups/`.
