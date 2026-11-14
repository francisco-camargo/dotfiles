---
name: markdown-audit
description: Audit a repo's Markdown in three passes, its pre-commit hooks, the writing rules its CLAUDE.md files set, and how its files fit together (a README that says what the repo is and why it matters, one reader per file, every file linked and each fact said once), then propose a plan of commits and carry it out once approved. Use when asked to audit, review, or tidy a repo's Markdown, docs, or README.
---

# Audit a repo's Markdown

The audit runs three passes, reports, and changes nothing until the user approves a plan of commits.
A script makes the fixed checks; reading makes the rest.

## 1. Run the report

```bash
~/.claude/skills/markdown-audit/scripts/check.sh [project-dir] [--no-pre-commit]
```

The project defaults to the current directory, and the script works from the root of its git repo.
It reads only tracked Markdown files, so build output and vendored packages stay out.

It prints:

- **Instructions in force:** the global `~/.claude/CLAUDE.md`, the repo's `CLAUDE.md`, and any in a subdirectory, which applies to files under it.
- **Pre-commit:** each failing hook, and what the fixers changed.
- **Pattern hits:** `file:line: rule: text`, each tagged with the `CLAUDE.md` heading of the rule it may break.
- **Lengths worth a look:** a README past 150 lines, another file past 400, any file under 20.
- **Links:** files the README does not reach, files nothing links to, files with no link back up, and plans `TODO.md` does not link to.

Pre-commit's fixers rewrite files.
On a tree with uncommitted changes, the script says so and shows only what the fixers changed, from a snapshot taken before the run.
Leave their changes in place for the plan in step 5; do not revert them, since a revert could take the user's own edits with it.

## 2. Pass 1: pre-commit

Report each failing hook and what it found.
If the repo has no `.pre-commit-config.yaml`, say so and point at the repo-template-check skill, which offers one.

## 3. Pass 2: writing style

Read every `CLAUDE.md` the report lists, and pull out the rules about prose and Markdown.
If none states any, skip this pass and say so.

The repo's own `CLAUDE.md` files are the authority.
Sort each finding by where its rule comes from:

- **The repo's rules:** a rule a `CLAUDE.md` in the repo states, for files under that file's directory.
- **The owner's style:** a rule only the global `~/.claude/CLAUDE.md` states. Report these in a section of their own, since another person's repo need not follow them.

Then work through the hits:

- Drop each hit whose rule no `CLAUDE.md` in force states.
- Read each remaining hit in its line and drop the false ones. A hit is a place to look: "new" in "a new machine" dates nothing, and a proper noun in a heading is no breach of sentence case.
- When one rule has many hits, give the count and a few examples, not every line.

Patterns cannot check most of the rules, so read each file for the rest: the passive voice, long words, figures of speech, getting to the point, and claims that will go stale.

Check what each document says about the repo against the repo: a file path, a command, a setting, a script's flags.
A stale fact misleads a reader more than a broken style rule does.

## 4. Pass 3: structure

Read [the structure rules](references/structure.md) and judge the family of files against them.
Run this pass whether or not the repo has a `CLAUDE.md` or a pre-commit config.

Report, in this order:

- The one sentence that says what the repo is and why it matters, written from the README's first screen, and whether that was easy to write.
- The reader of each file, and any passage that addresses someone else.
- What to split or merge, and why.
- Each file the link report lists, with the link to add or the reason it needs none.
- Any fact stated in two files, and which file should keep it.

## 5. Propose the plan

Present the findings by pass, each with its file and line, the rule or reason, and the fix.
Then lay out the commits that would fix them: every subject and what goes in each, one idea per commit.
Pre-commit fixers' changes left from step 1 make a cleanup commit of their own.

Ask for approval once, with AskUserQuestion, and put everything needed to answer inside the question and its options, since text written right before a question may not reach the user.
Let the user drop or change commits.

## 6. Carry it out

Make each approved commit in turn, following the user's commit conventions.
After the last, run `check.sh` again and report what is left, and why each item left stands.

End with a message that repeats what was left out and why, since explanations given between steps may not have reached the user.
