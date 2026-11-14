# Plan: parallel Claude sessions on one repo

## Goal

Several Claude Code sessions can work on one repo at once, each in its own git worktree on its own branch, and each lands its work on `main` without disturbing the others.
The standing instructions and a skill say how to start, land, and clean up a session, so it works the same in every repo.

## Why

Two sessions in one working tree edit the same files, stage each other's changes, and commit half-finished work.
A worktree gives each session its own files and index while sharing one `.git`, so branches, history, and hooks stay common.

## What to find out first

Claude Code has its own worktree support: a `--worktree` (`-w`) flag on `claude`, the `EnterWorktree` and `ExitWorktree` tools, and `isolation: "worktree"` for subagents.
Before writing any instructions, try them in a scratch repo and record here:

- Where the worktree goes (expected: `.claude/worktrees/<name>/` inside the repo) and what branch it makes.
- Whether Claude adds that directory to an ignore file, or leaves it to show up as untracked.
- What happens to the worktree and branch when the session ends, with and without uncommitted changes.
- Whether a `.worktreeinclude` file copies gitignored files, such as `.env` or `.claude/settings.local.json`, into the worktree.
- Whether a worktree shares the main checkout's project memory and permissions, or starts empty.
- How the VS Code extension and the desktop app start a session in a worktree, compared with the CLI.
- Whether pre-commit hooks run in a worktree, since `.git/hooks` lives in the shared git directory.

If the built-in support covers starting and cleaning up, the work below is a convention and a landing skill; if not, it is also a script that wraps `git worktree add`.

## The working loop

1. Start: a session gets a worktree on a fresh branch cut from `main`, named for the task.
2. Work: commit small and often on that branch, under the usual commit rules.
3. Land: rebase the branch on the latest `main`, run the repo's checks, and fast-forward `main` to it. The branch was never pushed, so rebasing it breaks no rule.
4. Clean up: remove the worktree and delete the branch.

Landing goes through the existing commit and push prompts, so nothing reaches `main` without the user's approval.

## Known hazards

- **Shared files:** two sessions that both edit `TODO.md` or one plan will conflict at landing. One plan per session keeps most work apart; `TODO.md` edits stay small and rebase cleanly.
- **Per-worktree setup:** each worktree needs its own `.venv` (`uv sync`) and any other ignored build output.
- **This repo's install:** `install.sh` run from a worktree would point `~/.claude/` at the worktree's files. Run it only from the main checkout.
- **Windows path length:** a worktree nested under `.claude/worktrees/` lengthens every path in it.

## Steps

- [ ] Try Claude Code's worktree support in a scratch repo and write the answers into "What to find out first".
- [ ] Make Git ignore `.claude/worktrees/` in every repo, by the route the open question settles.
- [ ] Add a "Parallel sessions" section to `claude/CLAUDE.md`: when to use a worktree, branch naming, and the working loop.
- [ ] Write a `land-branch` skill: rebase the session branch on `main`, run the checks, fast-forward `main`, then remove the worktree and branch.
- [ ] Run two sessions on this repo at once, each on its own plan, and land both.

## Docs to update

- [ ] `README.md`: add the skill to "What's here" and "Skills".
- [ ] `docs/standing-instructions.md`: mention the "Parallel sessions" section if it lists the file's sections.
- [ ] `TODO.md`: drop this plan's line once done.

## Updates to send

None.

## Open questions

- Where to ignore `.claude/worktrees/`: a global excludes file from the [git config plan](git-config.md), or repo-template's `.gitignore`. I lean towards the global excludes file, since it covers repos that never took the template, but it waits on that plan.
- Whether landing should fast-forward `main` locally or open a pull request. I lean towards local fast-forward for solo repos, since a pull request adds a round trip with no reviewer.
- Whether to keep worktrees inside the repo (Claude's default) or beside it, such as `../<repo>.worktrees/<name>/`. I lean towards Claude's default, unless path length bites on Windows.

## Done when

Two sessions worked on this repo at once, each in its own worktree, and both landed on `main` with no stray files, worktrees, or branches left: `git worktree list` shows only the main checkout and `git branch` shows only `main`.
