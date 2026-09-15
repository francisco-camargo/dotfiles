---
name: memory-audit
description: Find the Claude Code memory files kept for a project, recommend a visible home for each (a CLAUDE.md, a hook, a skill, a TODO list, the README) or keeping or deleting it, then carry out the plan once approved. Use when asked to audit, review, clean up, migrate, or get rid of Claude memories.
---

# Audit a project's memories

Claude Code keeps per-project memory outside every repo, where nobody sees it in day-to-day work.
This skill moves each memory into a file the user reads and commits, and deletes the memory once its content lives there.
Change nothing until the user approves the plan.

## 1. Find the memories

```sh
~/.claude/skills/memory-audit/scripts/find.sh [project-dir]
```

The project defaults to the current directory; `--all` covers every project that has memory files.
The script prints `MEMORY.md`, each memory file in full, and any mismatch between the index and the files.
It changes nothing.

If the project has no memories, say so, offer `--all`, and stop.

## 2. Decide a home for each memory

The global `CLAUDE.md` has a "Memory" section listing where each kind of fact belongs; follow it.
For each memory, pick one action:

- **Move to the global `CLAUDE.md`:** a preference or rule that holds in every project.
- **Move to the repo's `CLAUDE.md`:** a convention for one repo.
- **Move to a hook or permission rule** in `settings.json`: a rule that must hold every time.
- **Move to a skill:** a procedure repeated across sessions.
- **Move to the repo's TODO list or issue tracker:** unfinished work.
- **Move to the README or `docs/`:** the reason for a decision, or a pointer to an outside resource.
- **Delete:** the fact is wrong, stale, or a visible file already says it.
- **Keep:** no visible file can hold it, such as context about a repo the user cannot commit to, or a fact too private for git.

Before recommending, check each memory against the world:

- **Search the destination** for the fact, since a file may already cover it, fully or in part. Say which, and quote the covering line.
- **Verify every file, setting, and flag the memory names** still exists and still works the way it says.
- **Leave out machine specifics** such as absolute paths and host names when moving a fact into a portable file.
- **Find the real file behind the global `CLAUDE.md` and `settings.json`.** When `~/.claude/CLAUDE.md` is a symlink, edit its target; when it is a copy from a dotfiles repo, edit the repo's file, since the next install overwrites the copy.

## 3. Present the plan

Show one entry per memory:

- the memory's name, and its gist in a sentence
- the action, and the reason in a clause
- the destination file and section
- the exact text to add, written in the destination's own style

Where two actions are reasonable, give both and mark the one you recommend.

Then lay out the commits: one per destination change, with every subject, and the repo each lands in.
Memory files sit outside git, so deleting one cannot be undone; say that deletion follows only after the content is committed elsewhere.

End the turn and wait for approval.
The user may approve all of it, change entries, or approve some.

## 4. Carry out the approved plan

Take the entries one at a time:

1. Edit the destination file.
2. Stage it by path and commit, following the user's commit conventions.
3. Once the commit lands, delete the memory file and remove its line from `MEMORY.md`.

When the user refuses a commit, leave that memory in place.
Delete a "Delete" entry's file and index line with no commit.
When `MEMORY.md` has no entries left, delete it.

A change to `settings.json` takes effect only after Claude Code restarts or `/hooks` is opened once; say so.

## 5. Report

Run the script again to show what remains.
End with a message listing each memory and what became of it: the file it moved to and the commit hash, deleted, or kept and why.
Say that the running session still has the old memories loaded until it restarts.
