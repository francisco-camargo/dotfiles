# How a repo's Markdown files fit together

Pass 3 judges the family of Markdown files against these rules.
No outside standard covers this, so treat each rule as an opinion to apply with judgment, and say so when a repo has a good reason to differ.

## The README answers three questions first

A reader who stops after the opening paragraphs must know:

- what the repo is
- who it is for
- why they should care: the problem it solves, or what it gives them

Install steps, usage, and layout come after.

The check: read only the title and the first screen, then write one sentence saying what the repo is and why it matters.
Put that sentence in the report.
If it was hard to write, or wrong, the README fails, whatever else it does well.

## Each file has one reader

| File | Reader |
| --- | --- |
| `README.md` | Someone who has never seen the repo |
| `docs/*.md` | A user who needs depth on one topic |
| `CONTRIBUTING.md` | Someone about to change the repo |
| `CLAUDE.md` | Claude, working in the repo |
| `SKILL.md` and its `references/` | Claude, doing the task the skill names |
| `TODO.md` | The owner |
| `plans/*.md` | The owner, while the work is under way |
| `SECURITY.md` | Someone reporting a vulnerability |

A file written for two readers serves neither.
Name the reader of each file, and quote the passages that address someone else, such as contributor setup in a README or a design rationale in a `CLAUDE.md`.

## When to split and when to merge

Split a file when:

- a section serves a different reader from the rest
- a section covers a task readers do apart from the rest, such as install versus daily use
- the file no longer reads in one sitting

Merge files when:

- one is too short to stand alone
- readers always need both together
- two files say the same thing

The script's length report is a signal to look, not a verdict.
A short `SECURITY.md` or `CLAUDE.md` that does its one job stays as it is.

## Every file is reachable, and said once

- The README links to every other document, directly or through one index.
- Each document links back up to the README or its index.
- No file is an orphan that nothing links to.
- Each fact lives in one file, and other files link to it.

The script's link report lists the files that break the first three.
It counts a plan that `TODO.md` links to as linked back, since `TODO.md` is the plans' index.
Some files need no link by design: a `CLAUDE.md` that Claude loads by path, a `SKILL.md` that Claude loads by its description, `SECURITY.md` that GitHub shows on its own tab.
Say why each one listed is fine, or propose the link.

The fourth needs reading: look for a fact, such as a command, a path, or a rule, stated in two files, and propose which file keeps it.

## Plans follow the planning skill

Where a repo has `TODO.md` or `plans/`, check them against the layout the planning skill sets out, at `~/.claude/skills/planning/SKILL.md`, and cite that skill for each finding rather than restating its rules.
The script lists plans that `TODO.md` does not link to; the rest, such as a plan with no goal or no done-when check, needs reading.
