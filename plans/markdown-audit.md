# Plan: audit a repo's Markdown

## Goal

Write a `markdown-audit` skill that audits any repo's Markdown against its pre-commit hooks, its writing rules, and an opinion on how its Markdown files fit together.

## Why

A reader must never be confused about what a repo is or why they should care, and each document must suit the reader it is for.
Pre-commit and a style guide check sentences; nothing checks whether the files as a family serve their readers.

## What the skill does

The skill audits a repo's Markdown in three passes, reports, and changes nothing until the user approves a plan of commits.
It follows the shape of `repo-template-check` and `memory-audit`: a script for the fixed checks, the model for judgment, then one approval.

### Pass 1: pre-commit

- If the repo has `.pre-commit-config.yaml`, run `pre-commit run --all-files` and report each failing hook.
- The fixers rewrite files, so run on a clean working tree, or report that the tree was dirty and show what the fixers changed.
- If the repo has no config, say so and point at `repo-template-check`, which offers one.

### Pass 2: writing style

- Collect the instructions that apply to the repo: `~/.claude/CLAUDE.md`, the repo's `CLAUDE.md`, and any `CLAUDE.md` in a subdirectory, which applies to files under it.
- Pull out the rules about prose and Markdown. If there are none, skip the pass and say so.
- Check by pattern where a rule allows it (em dashes, filler words, dating words, bold lead-ins, fences without a language, several sentences on one line), and by reading for the rest (passive voice, getting to the point, stale claims).
- Check facts a document states about the repo against the repo, as the stale `init.templateDir` claim fixed in `6f90ac8` shows.

### Pass 3: structure

Judge the family of Markdown files as a whole, against the opinion below.

## The structure opinion

This is the part with no outside standard, so it needs the owner's review most.

### The README answers three questions first

A reader who stops after the opening paragraphs must know:

- what the repo is
- who it is for
- why they should care: the problem it solves, or what it gives them

Install steps, usage, and layout come after.
The check: read only the title and the first screen, then write one sentence saying what the repo is and why it matters.
If that sentence is hard to write, or wrong, the README fails, whatever else it does well.

### Each file has one audience

| File | Reader |
| --- | --- |
| `README.md` | Someone who has never seen the repo |
| `docs/*.md` | A user who needs depth on one topic |
| `CONTRIBUTING.md` | Someone about to change the repo |
| `CLAUDE.md` | Claude, working in the repo |
| `TODO.md` | The owner |
| `plans/*.md` | The owner, while the work is under way |
| `SECURITY.md` | Someone reporting a vulnerability |

A file written for two readers serves neither; the audit names the reader for each file and flags the passages that address someone else.

### When to split and when to merge

Split a file when:

- a section serves a different reader from the rest
- a section covers a task readers do apart from the rest, such as install versus daily use
- the file no longer reads in one sitting

Merge files when:

- one is too short to stand alone
- readers always need both together
- two files say the same thing

Line counts are a signal to look, not a verdict.
Proposed starting points: a README past about 150 lines, any other file past about 400, a file under about 20 lines.

### Every file is reachable, and said once

- The README links to every other document, directly or through one index.
- Each document links back up to the README or its index.
- No file is an orphan that nothing links to.
- Each fact lives in one file, and other files link to it.

## Layout

```text
claude/skills/markdown-audit/
  SKILL.md                 the three passes, the report, the approval step
  references/structure.md  the structure opinion, read in pass 3
  scripts/check.sh         pre-commit run, pattern checks, line counts, link graph
```

The structure opinion goes in `references/` so `SKILL.md` stays short and the opinion loads only for pass 3.

## Steps

- [ ] Settle the open questions below, and the structure opinion with its line counts.
- [ ] Write `check.sh` and run it on this repo.
- [ ] Write `SKILL.md` and `references/structure.md`, and install the skill.
- [ ] Run the skill on this repo, `repo-template`, and one repo with no `CLAUDE.md` and no pre-commit config, and fix what the runs show.

## Docs to update

- [ ] `README.md`: list the skill in the file table and the skills list.
- [ ] [The prose checks plan](prose-checks.md): say which pattern checks `check.sh` already makes, once the overlap question is settled.
- [ ] [The planning skill](../claude/skills/planning/SKILL.md): link to this skill for checking a repo's plans, if the audit takes that on.

## Updates to send

None: the skill runs only on this repo's owner's machines, and no ticket tracks it.

## Open questions

- **Name:** `markdown-audit`, or `docs-audit`, since pass 3 is about documentation more than Markdown? Leaning `markdown-audit`, since "audit the markdown" is how a request would be worded.
- **Duplicated rules:** pattern checks in `check.sh` repeat rules that live in `CLAUDE.md`. Leaning: the script reports every hit tagged with its rule, and the skill keeps only hits whose rule a `CLAUDE.md` in force states, so `CLAUDE.md` stays the authority.
- **Overlap with the prose checks plan:** [Check Markdown after Claude writes it](prose-checks.md#check-markdown-after-claude-writes-it) and [Check prose with Vale](prose-checks.md#check-prose-with-vale) cover the same pattern checks. Leaning: the hook there calls `check.sh`, so the patterns live in one script.
- **A style skill:** [Split standing instructions between CLAUDE.md and skills](standing-instructions-split.md) expects a writing style guide to become the first skill split out of `CLAUDE.md`. The structure opinion could be that guide's first part.
- **Repos without your rules:** in someone else's repo, should pass 2 apply your global `CLAUDE.md`, or only the repo's own? Leaning: the repo's own, with hits against the global rules reported apart as the owner's style.
- **Plans layout:** should pass 3 check that a repo follows the [planning skill](../claude/skills/planning/SKILL.md)'s layout of `TODO.md` and `plans/`? Leaning yes, linking to the planning skill for the rule, so it lives in one place.

## Done when

Run on `0a2d48e`, the commit before the hand audit, the skill reports the problems that commits `a7d18a4` to `e1467c1` fixed.
Run on a repo with no `CLAUDE.md` and no pre-commit config, it still reports on structure.
