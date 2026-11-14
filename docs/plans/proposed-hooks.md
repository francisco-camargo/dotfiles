# Plan: proposed hooks

## Goal

Decide which of the gates below to add, and add those, each with a case in `tests/hooks-test.sh`.

## Why

Claude drafted these on 2026-09-15, and the owner has not read them in detail.
Nothing here is decided.

## The proposals

Each adds a pattern escaped inside JSON, which strengthens the case for [the hook scripts plan](hook-scripts.md).

### Block `pip install`

- **What it catches:** `pip install` and `pip3 install`, which the [uv gate](../hooks.md#the-uv-gate) lets through although they reach for the same missing interpreter.
- **Form:** widen the uv gate's pattern rather than add a hook. `uv pip install` still passes, because the gate matches `pip` only where it starts a command.
- **Refusal text:** `uv add` for a project dependency, `uv pip install` inside a venv, `uvx` or `uv tool install` for a command-line tool.

### Block staging everything

- **What it catches:** `git add -A`, `git add --all`, `git add .`, and `git commit -a` or `-am`, which enforces the rule in [claude/CLAUDE.md](../../claude/CLAUDE.md) to stage files by path.
- **Deny or ask:** deny, so Claude retries with paths in the same turn, as it does after the uv gate.
- **Gaps:** `git add *` and `git add docs/` still stage broadly, and a pattern cannot judge them. `git add ./file` and `git add -u` stay allowed.

### Name `--no-verify` in the commit prompt

- **What it catches:** the flag that skips every check in [the commit gates](../security.md#the-commit-gates).
- **Deny or ask:** ask, so skipping the checks on purpose stays possible. The git gate already asks on every commit, but its prompt does not mention the flag, so the owner could approve without noticing. The change is a second reason in the git gate that names the flag.
- **Gaps:** `SKIP=gitleaks git commit` and `git -c core.hooksPath=... commit` skip the checks too. `-n` means no-verify to `commit` but dry run to `push`, so the pattern has to tell them apart.

### Edit the repo, not the installed copy

- **What it catches:** Claude editing `~/.claude/CLAUDE.md`, `settings.json`, or one of this repo's skills in place, which has already lost work once ([copies drift both ways](../install.md#copies-drift-both-ways)). The only guard is a rule the owner has to remember.
- **Form:** a `PreToolUse` hook on `Edit` and `Write` that denies a path `install.sh` places, and says to edit the repo and re-run the installer. It leaves `~/.claude/projects/`, where memory lives, and other skills alone.
- **Catch:** the hook needs its own list of the paths `install.sh` places, a second source of truth. Either `install.sh` drops a marker beside each copy for the hook to look for, or real symlinks under Developer Mode may make the hook unneeded.

## Steps

- [ ] Read each proposal, and keep, change, or drop it.
- [ ] Widen the uv gate to refuse `pip install`.
- [ ] Add the gate that refuses staging everything.
- [ ] Name `--no-verify` in the git gate's prompt.
- [ ] Add the gate on installed copies, or drop it if symlinks make it unneeded.

## Docs to update

- [ ] [docs/hooks.md](../hooks.md): a section for each gate added.
- [ ] `README.md`: the gate list under Hooks.

## Updates to send

None.

## Open questions

- **Order:** add these before or after [the hook scripts plan](hook-scripts.md)? Leaning after, so each new gate is a script from the start.

## Done when

Each proposal is added or dropped, and `tests/hooks-test.sh` passes with a case for each gate added.
