# Plan: make the gates easy to adopt

## Goal

Someone who keeps their own `settings.json` can take the gates without merging JSON by hand: each gate lives in a script, and a project can commit the gates to its own `.claude/settings.json`.

## Why

`install.sh` asks before replacing someone's settings ([`install.sh` and an existing `settings.json`](../docs/install.md#installsh-and-an-existing-settingsjson)), so the gates are all or nothing for a person with settings of their own.

## Why not merge the files

A real merge needs a JSON parser, and the rule that keeps the hooks portable (`sed` and `grep` only, no `jq`, no `node`, no `python`) is the same rule that makes merging JSON inside `install.sh` a bad idea.
A merger written in awk would fail quietly on a nested key, which is the failure this repo keeps trying to design out.

## The two pieces

- **Hook bodies in scripts.** `claude/hooks/git-gate.sh`, `sed-gate.sh`, and `uv-gate.sh`, with `settings.json` holding stanzas that call them. It shrinks the block a person has to paste, and makes each gate testable on its own rather than by pulling a string back out of JSON, which the uv gate's escaping already argues for.
- **The project-level route.** Hook entries merge across settings levels rather than replacing each other, so the gates work committed to a project's `.claude/settings.json`. Everyone who clones that repo gets the gates, and no home directory is touched.

## Steps

- [ ] Move each gate's body into a script under `claude/hooks/`, have `settings.json` call it, and have `install.sh` place `claude/hooks/`.
- [ ] Point `tests/hooks-test.sh` at the scripts.
- [ ] Write the project-level route as a snippet a repo can commit.

## Docs to update

- [ ] [docs/hooks.md](../docs/hooks.md): the gates live in scripts; revise the rules about JSON escaping.
- [ ] [docs/install.md](../docs/install.md#installsh-and-an-existing-settingsjson): point a person with their own settings at the scripts and the project-level route.
- [ ] `README.md`: add `claude/hooks/` to the file table.
- [ ] repo-template's `TODO.md`: its `.claude/settings.json` item links here; point it at the snippet once this plan is deleted.

## Updates to send

None.

## Open questions

- **Where the scripts come from in a project:** a project's `.claude/settings.json` can call `~/.claude/hooks/`, which needs these dotfiles installed, or the project can carry copies in `.claude/hooks/`. Leaning: copies, from repo-template, so a clone works on any machine.

## Done when

`settings.json` holds only stanzas that call scripts, `tests/hooks-test.sh` passes against the scripts, and a repo with only a committed `.claude/settings.json` asks before `git commit`.
