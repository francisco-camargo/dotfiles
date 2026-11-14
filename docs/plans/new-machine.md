# Plan: set up a new machine

Three pieces: install the tools the config assumes, check the result, and put the steps in one order.

## Install what this config already assumes

The [uv gate](../hooks.md#the-uv-gate) refuses a bare `python` and tells Claude to run `uv` instead, and the [commit gates](../security.md#the-commit-gates) need `pre-commit`.
A new machine has neither.
So the first session after an install meets a hook demanding a tool that is not there, and `install.sh` ends by announcing that the gates are off: the repo naming a hole it could fill.

What closes it is a list of what a machine needs, kept as a file rather than a run of install lines: git, `gh`, `uv`, `pre-commit`, VS Code.
`winget export` writes that list from a machine that already works and `winget import` replays it, which keeps it a file you can read and diff rather than a script you have to run to find out what it does, for the same reason the VS Code extensions list in [VS Code settings](../../TODO.md#vs-code-settings) is a file.

It stays separate from `install.sh`.
Installing tools onto a machine is a larger claim than placing config files, and making it a side effect of the second is the trade `install.sh` already refuses when it declines to install `pre-commit` for you.

## Verify the machine, not only write to it

`install.sh` places files and reports what it did.
Nothing answers the question that comes next on a new machine: is this right yet?
The only answer is to read the docs and check by hand.

A `doctor.sh` would report state and change nothing:

- link or copy, for each installed target
- whether Developer Mode is on
- which installed copies differ from the repo
- whether this clone has a `pre-commit` hook in `.git/hooks/`
- whether `uv` and `gh` are on PATH

Two of those are worth more than a status line.
The difference check already exists in `install.sh`, which uses it to decide when to ask before replacing a file, so the doctor can share it.
And a doctor script is where the test that [Hooks](../hooks.md) demands can live: pull each pattern back out of `settings.json`, feed it a sample tool payload, and confirm it still matches.
A gate that quietly stopped firing is the failure this repo keeps designing against, and nothing checks for it.

`sed` and `grep` only, for the reason the hooks are.

## Put the new-machine steps in one order

The steps are all written down and none of them are together.
Developer Mode opens [Install on a new machine](../../README.md#install-on-a-new-machine), `pre-commit` arrives in `install.sh`'s closing warning, restarting Claude Code is the line after the install command, and authenticating to GitHub is nowhere, because cloning is where the instructions start.
Someone setting up a machine wants the sequence once, in one place:

1. Developer Mode, first, because it decides whether the install links or copies
2. git, and the tools the config assumes
3. authentication: `gh auth login`, or an SSH key
4. clone, `./install.sh --dry-run`, then `./install.sh`
5. restart Claude Code

Each step already has a section arguing it.
The list is a table of contents for one afternoon, not a replacement for them.
