# TODO

A short index of what could come next.
Every item is summarized in one line here and argued properly in [README.md](README.md) — follow the link before acting on one.

## Open items

Started and unfinished, as opposed to speculative — [Open items](README.md#open-items).

- [ ] Turn on Developer Mode, which ends the copying and makes edits propagate ([turn on Developer Mode](README.md#turn-on-developer-mode))
- [ ] Ask before `install.sh` replaces a file that is already there, and keep it by default ([ask before replacing a file](README.md#ask-before-replacing-a-file))
- [ ] Make the hooks easy to adopt for someone who keeps their own `settings.json` ([merge settings.json](README.md#merge-settingsjson-instead-of-replacing-it), [the warning](README.md#installsh-replaces-settingsjson-wholesale))
- [ ] Decide what stays in `CLAUDE.md` and what becomes a skill — writing style is the first case, not the only one ([split standing instructions](README.md#split-standing-instructions-between-claudemd-and-skills))
- [ ] Prune `~/.claude/backups/`, with a `--keep N` or a date cutoff ([prune backups](README.md#prune-claudebackups))
- [ ] Delete the duplicate `md-to-pdf` in the other repo and let this one own it ([skill scope, and duplicates](README.md#skill-scope-and-duplicates))
- [ ] Consolidate this `.pre-commit-config.yaml` with the Python one, and audit what each is missing ([consolidate the two configs](README.md#consolidate-the-two-pre-commit-configs))
- [ ] Settle how spelling gets checked — `codespell` at commit time, `cspell` in the editor, or both ([settle how spelling gets checked](README.md#settle-how-spelling-gets-checked))
- [ ] Install what this config already assumes — a new machine has neither `uv` nor `pre-commit` ([install what this config assumes](README.md#install-what-this-config-already-assumes))
- [ ] Report the state of a machine with a `doctor.sh`, including whether each gate still fires ([verify the machine](README.md#verify-the-machine-not-only-write-to-it))
- [ ] Put the new-machine steps in one order, authentication included ([one order](README.md#put-the-new-machine-steps-in-one-order))
- [ ] Add a root `SECURITY.md` and turn on private vulnerability reporting ([add a SECURITY.md](README.md#add-a-securitymd))

## Someday

Speculative rather than missing, and deliberately not enumerated here — [What else could live here](README.md#what-else-could-live-here) lists the candidates and the rule for when one earns a place.
