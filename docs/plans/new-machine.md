# Plan: set up a new machine

## Goal

Bring a new machine to a working state by following one ordered list, and have a script report when it is right.

## Why

The [uv gate](../hooks.md#the-uv-gate) refuses a bare `python` and tells Claude to run `uv` instead, and the [commit gates](../security.md#the-commit-gates) need `pre-commit`.
A new machine has neither, so the first session after an install meets a hook demanding a tool that is not there, and `install.sh` ends by announcing that the gates are off.
And once the install is done, nothing answers the question that comes next: is this right yet?

## Install what this config already assumes

A list of what a machine needs, kept as a file rather than a run of install lines: git, `gh`, `uv`, `pre-commit`, VS Code.
`winget export` writes that list from a machine that already works and `winget import` replays it, which keeps it a file you can read and diff, for the same reason the VS Code extensions list in [the VS Code settings plan](vscode-settings.md) is a file.

It stays separate from `install.sh`.
Installing tools onto a machine is a larger claim than placing config files, and making it a side effect of the second is the trade `install.sh` already refuses when it declines to install `pre-commit` for you.

## Verify the machine

A `doctor.sh` would report state and change nothing:

- link or copy, for each installed target
- whether Developer Mode is on
- which installed copies differ from the repo
- whether this clone has a `pre-commit` hook in `.git/hooks/`
- whether `uv` and `gh` are on PATH
- whether `tests/hooks-test.sh` passes

The difference check already exists in `install.sh`, which uses it to decide when to ask before replacing a file, so the doctor can share it.
The hooks test runs only when someone remembers to run it after [editing a gate](../hooks.md#run-the-test-after-a-change), and a gate that quietly stopped firing is the failure this repo keeps designing against.
`sed` and `grep` only, for the reason the hooks are.

## The steps in one order

Each step is written down somewhere, and none of them are together.
Developer Mode opens [Install on a new machine](../../README.md#install-on-a-new-machine), `pre-commit` arrives in `install.sh`'s closing warning, restarting Claude Code is the line after the install command, and authenticating to GitHub is nowhere.
The order:

1. Developer Mode, first, because it decides whether the install links or copies
2. git, and the tools the config assumes
3. authentication: `gh auth login`, or an SSH key
4. clone, `./install.sh --dry-run`, then `./install.sh`
5. restart Claude Code
6. `./doctor.sh`

Each step already has a section arguing it; the list links to them rather than replacing them.

## Steps

- [ ] Write the tools list with `winget export`, trimmed to what this config assumes.
- [ ] Write `doctor.sh`, sharing `install.sh`'s difference check.
- [ ] Have `doctor.sh` run `tests/hooks-test.sh`.
- [ ] Write the ordered steps in one place.

## Docs to update

- [ ] `README.md`: the ordered steps under Install on a new machine, and the new files in the file table.
- [ ] [docs/install.md](../install.md): the tools list and the doctor.
- [ ] [docs/hooks.md](../hooks.md#run-the-test-after-a-change): the doctor runs the test too.

## Updates to send

None.

## Open questions

- **Where the ordered steps go:** the README's install section, or [docs/install.md](../install.md). Leaning the README, since a newcomer starts there.

## Done when

Following the list on a fresh Windows machine ends with `doctor.sh` reporting no problems.
