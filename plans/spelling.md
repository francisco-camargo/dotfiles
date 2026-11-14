# Plan: settle how spelling gets checked

## Goal

Decide whether `cspell` runs only in the editor or also at commit beside `typos`, and confirm its word list with a run.

## How spelling is checked

`cspell.json` sits in the repo root and the VS Code extension finds it without being told to, so a misspelling is underlined as it is typed.
When a commit is created, `typos` checks it, from the pre-commit config this repo shares with [repo-template](https://github.com/francisco-camargo/repo-template/blob/main/template/.pre-commit-config.yaml).
Neither config has a `cspell` hook, so nothing runs `cspell` outside the editor.

The two tools work differently.
`typos` carries a list of known misspellings and flags only those, which keeps it quiet and spares it a word list.
`cspell` works from dictionaries and flags anything absent from them, which is stricter and is why the word list in `cspell.json` had to be written before it was usable here.
That list was written by reading the repo and judging what the dictionaries already cover, and no run has confirmed it.

## What a `cspell` hook would cost

- **A second runtime.** Its hook is `language: node`, so `pre-commit` fetches a node runtime into `~/.cache/pre-commit`, the way it fetches the Go toolchain for `gitleaks`. Nothing has to be installed on the machine.
- **Two lists of exceptions** that drift apart, because each tool has to be told its own.

## Steps

- [ ] Run `cspell` once over the repo, through `npx cspell` or a hook added for the run, and fix the word list it shows wrong.
- [ ] Decide: editor only, or a hook at commit too.
- [ ] If a hook, add it to repo-template's `.pre-commit-config.yaml` and copy it here.

## Docs to update

- [ ] [claude/CLAUDE.md](../claude/CLAUDE.md): the Spelling section, if a hook is added.
- [ ] repo-template's `plans/shared-docs.md`: it links here; remove the link once this plan is deleted.

## Updates to send

None.

## Open questions

- **Editor only, or a hook too:** leaning editor only, and add the hook if a misspelling gets past `typos`.

## Done when

A `cspell` run over the repo reports nothing, and the decision is recorded in the Spelling section of `claude/CLAUDE.md` or in repo-template's config.
