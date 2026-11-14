# Plan: audit a repo's Markdown

Two pieces of work, in order:

1. Fix the Markdown in this repo, from the audit already done.
2. Write a `markdown-audit` skill that runs the same audit on any repo, and adds an opinion on how a repo's Markdown files should fit together.

The first is the worked example for the second: every check the skill makes should have caught something in step 1.

## Part 1: fix this repo

The audit found no pre-commit failures and these breaks from the writing rules in `claude/CLAUDE.md`.
One commit each:

1. `Convert md-to-pdf skill to one sentence per line` (staged, not committed)
2. `Replace em dashes in TODO and security docs`
3. `Cut filler words from the docs`, including the `docs/install.md` link to the renamed heading
4. `Drop words that date TODO and security docs`
5. `Make security.md's bold lead-ins headings`
6. `Bring security.md's hook-install history up to date`: the global `init.templateDir` hook it calls future work, which `install.sh` already sets; the settled scanner debate; the 340 MB figure; the one-off history search
7. `Link within TODO.md by anchor alone`

## Part 2: the skill

### What it does

The skill audits a repo's Markdown in three passes, reports, and changes nothing until the user approves a plan of commits.
It follows the shape of `repo-template-check` and `memory-audit`: a script for the fixed checks, the model for judgment, then one approval.

#### Pass 1: pre-commit

- If the repo has `.pre-commit-config.yaml`, run `pre-commit run --all-files` and report each failing hook.
- The fixers rewrite files, so run on a clean working tree, or report that the tree was dirty and show what the fixers changed.
- If the repo has no config, say so and point at `repo-template-check`, which offers one.

#### Pass 2: writing style

- Collect the instructions that apply to the repo: `~/.claude/CLAUDE.md`, the repo's `CLAUDE.md`, and any `CLAUDE.md` in a subdirectory, which applies to files under it.
- Pull out the rules about prose and Markdown. If there are none, skip the pass and say so.
- Check by pattern where a rule allows it (em dashes, filler words, dating words, bold lead-ins, fences without a language, several sentences on one line), and by reading for the rest (passive voice, getting to the point, stale claims).
- Check facts a document states about the repo against the repo, as the `init.templateDir` claim in Part 1 shows.

#### Pass 3: structure

Judge the family of Markdown files as a whole, against the opinion below.

### The structure opinion

This is the part with no outside standard, so it needs your review most.

#### The README answers three questions first

A reader who stops after the opening paragraphs must know:

- what the repo is
- who it is for
- why they should care: the problem it solves, or what it gives them

Install steps, usage, and layout come after.
The check: read only the title and the first screen, then write one sentence saying what the repo is and why it matters.
If that sentence is hard to write, or wrong, the README fails, whatever else it does well.

#### Each file has one audience

| File | Reader |
| --- | --- |
| `README.md` | Someone who has never seen the repo |
| `docs/*.md` | A user who needs depth on one topic |
| `CONTRIBUTING.md` | Someone about to change the repo |
| `CLAUDE.md` | Claude, working in the repo |
| `TODO.md` | The owner |
| `SECURITY.md` | Someone reporting a vulnerability |

A file written for two readers serves neither; the audit names the reader for each file and flags the passages that address someone else.

#### When to split and when to merge

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

#### Every file is reachable, and said once

- The README links to every other document, directly or through one index.
- Each document links back up to the README or its index.
- No file is an orphan that nothing links to.
- Each fact lives in one file, and other files link to it.

### Layout

```text
claude/skills/markdown-audit/
  SKILL.md               the three passes, the report, the approval step
  references/structure.md  the structure opinion, read in pass 3
  scripts/check.sh       pre-commit run, pattern checks, line counts, link graph
```

The structure opinion goes in `references/` so `SKILL.md` stays short and the opinion loads only for pass 3.

### Steps

1. Agree this plan, especially the structure opinion and its numbers.
2. Write `check.sh` and run it on this repo; it should find what Part 1 fixed, on the commit before Part 1.
3. Write `SKILL.md` and `references/structure.md`.
4. Run the skill on this repo, `repo-template`, and one repo with no `CLAUDE.md` and no pre-commit config.
5. Add the skill to the README's table and skill list, and delete this plan.

## Open questions

- **Name:** `markdown-audit`, or `docs-audit`, since pass 3 is about documentation more than Markdown?
- **Duplicated rules:** pattern checks in `check.sh` repeat rules that live in `CLAUDE.md`. Either accept the copy, or have the script check a rule only when `CLAUDE.md` states it.
- **Overlap with TODO items:** [Check Markdown after Claude writes it](../TODO.md#check-markdown-after-claude-writes-it) and [Check prose with Vale](../TODO.md#check-prose-with-vale) cover the same pattern checks. This skill could be where they land, or they could replace its pattern checks.
- **A style skill:** [Split standing instructions between CLAUDE.md and skills](../TODO.md#split-standing-instructions-between-claudemd-and-skills) expects a writing style guide to become the first skill split out of `CLAUDE.md`. The structure opinion could be that guide's first part.
- **Repos without your rules:** in someone else's repo, should pass 2 apply your global `CLAUDE.md`, or only the repo's own?
