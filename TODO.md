# TODO

A short index of what could come next.
Every item is summarized in one line here and argued properly in [README.md](README.md) — follow the link before acting on one.

## Before the repo goes public

Gated, because publishing is the step no later commit can undo — [Before this repo goes public](README.md#before-this-repo-goes-public).

- [ ] Turn on GitHub push protection — a checkbox, highest value, and the only item no commit can do ([four layers](README.md#four-layers-and-what-each-one-misses))
- [x] Harden `.gitignore` against the files that would actually cost something ([how a secret would get out](README.md#how-a-secret-would-actually-get-out))
- [x] Add a repo-local `pre-commit` hook — the framework running `gitleaks`, not `sed` and `grep` ([the commit gates](README.md#the-commit-gates))
- [x] Audit the full history once more, deliberately ([the order to do it in](README.md#the-order-to-do-it-in))
- [ ] Turn on branch protection — public means strangers can propose changes to a script you execute ([this repo runs code](README.md#this-repo-runs-code-on-every-machine-that-installs-it))
- [ ] Decide whether the `gitleaks` workflow earns its keep, after living with the local hook ([four layers](README.md#four-layers-and-what-each-one-misses))

Already settled: the history keeps the old internal names, and that choice stops being reversible at the moment the repo is published — [already decided](README.md#already-decided-the-history-keeps-the-old-names).

## Open items

Started and unfinished, as opposed to speculative — [Open items](README.md#open-items).

- [ ] Turn on Developer Mode, which ends the copying and makes edits propagate ([turn on Developer Mode](README.md#turn-on-developer-mode))
- [ ] Guard a copy-mode install from overwriting newer work, with `--force` ([stop a copy-mode install](README.md#stop-a-copy-mode-install-from-overwriting-newer-work))
- [ ] Stop `install.sh` replacing `settings.json` wholesale ([merge settings.json](README.md#merge-settingsjson-instead-of-replacing-it), [the warning](README.md#installsh-replaces-settingsjson-wholesale))
- [ ] Decide what stays in `CLAUDE.md` and what becomes a skill — writing style is the first case, not the only one ([split standing instructions](README.md#split-standing-instructions-between-claudemd-and-skills))
- [ ] Prune `~/.claude/backups/`, with a `--keep N` or a date cutoff ([prune backups](README.md#prune-claudebackups))
- [ ] Delete the duplicate `md-to-pdf` in the other repo and let this one own it ([skill scope, and duplicates](README.md#skill-scope-and-duplicates))

## Someday

Speculative rather than missing, and deliberately not enumerated here — [What else could live here](README.md#what-else-could-live-here) lists the candidates and the rule for when one earns a place.
