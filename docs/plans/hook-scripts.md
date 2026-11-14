# Plan: merge `settings.json` instead of replacing it

Described in full under [`install.sh` and an existing `settings.json`](../install.md#installsh-and-an-existing-settingsjson).
`install.sh` asks before replacing someone's settings.
What is left is making the hooks easy to adopt for someone who keeps their own.

A real merge is the wrong fix.
It needs a JSON parser, and the rule that keeps the hooks portable (`sed` and `grep` only, no `jq`, no `node`, no `python`) is the same rule that makes merging JSON inside `install.sh` a bad idea.
A merger written in awk would fail quietly on a nested key, which is the failure this repo keeps trying to design out.

Two smaller pieces instead:

- **Hand other people the project-level route.** Hook entries merge across settings levels rather than replacing each other, so the gates work committed to a shared project's `.claude/settings.json`. Everyone who clones that repo gets the gates, and no home directory is touched.
- **Move the hook bodies into scripts.** `claude/hooks/git-gate.sh`, `claude/hooks/sed-gate.sh`, and `claude/hooks/uv-gate.sh`, with `settings.json` holding stanzas that call them. It does not fix the merge, but it shrinks the block a person has to paste and makes each hook testable on its own rather than by pulling a string back out of JSON, which the uv gate's escaping already argues for.
