# Plan: prune install backups

## Goal

`./install.sh --keep N` deletes all but the newest N backups of each file in `~/.claude/backups/`, touching only the backups `install.sh` made.

## Why

Every install that replaces a file adds a backup there, and nothing removes one, so the directory only grows.

## What counts as an install backup

`backup()` in `install.sh` names each backup `<name>.<YYYYMMDD-HHMMSS>`, from the run's `$stamp`.
Pruning matches that pattern and nothing else.

Claude Code writes its own backups into the same directory, as `.claude.json.backup.<milliseconds>`.
Those do not match the pattern and stay untouched.

Group by `<name>` and sort each group by its stamp, which sorts as text in time order.
Delete all but the newest N in each group, whether the entry is a file or a directory (skills back up as directories).

## Behaviour

- `--keep N` takes a whole number; anything else exits with status 2, like an unknown option.
- Pruning runs after the install, so a backup made by this run counts among the N.
- Under `--dry-run`, it prints what it would delete and deletes nothing, through the existing `run` helper.
- It prints each path it deletes.
- Without `--keep`, nothing is deleted: a backup may hold the only copy of something the user had.
- A count is the only rule; a date cutoff waits until a count proves wrong.

## Steps

- [x] Add `--keep N` to `install.sh`, with tests in `tests/install-test.sh` written first: keeps the newest N per name, leaves `.claude.json.backup.*` alone, deletes nothing under `--dry-run`, rejects a non-number.

## Docs to update

- [x] `install.sh` header: a usage line for `--keep N`, which `--help` prints.
- [x] `docs/install.md`, where it says a replaced file moves into `~/.claude/backups/`: name `--keep N`, and say it leaves Claude Code's own backups alone.

## Updates to send

None.

## Done when

`tests/install-test.sh` passes, and `./install.sh --keep 2` on this machine leaves two `md-to-pdf.*` backups and every `.claude.json.backup.*` file in place.
