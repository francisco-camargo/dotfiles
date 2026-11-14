# Plan: a skill for planning work

## Goal

Write a `planning` skill that writes plan files to one template, and keeps a repo's `TODO.md` and its plans in step.

## How a repo holds its plans

- Each piece of work that needs more than a line gets a plan, one file per piece of work, in `docs/plans/`.
- `TODO.md` stays short and high level: one line per item, linking to its plan where there is one.
- `TODO.md` orders the work, so it is where to decide what comes next.
- A plan is deleted once its work is done; git keeps the history.

This repo's `TODO.md` and `docs/plans/` are the first example.

## The plan template

Every plan has these sections, in this order:

- **Goal:** one or two sentences, so a reader knows what the plan is for before anything else.
- **Why:** only when the goal does not make the reason plain.
- **Steps:** a task list, each step about the size of a commit. Tick a step (`- [x]`) in the commit that completes it.
- **Docs to update:** a task list of the files the work makes stale, so a decision outlives the plan that made it.
- **Updates to send:** a task list of the people the work affects and the tickets, threads, and channels that track it, with what each needs to hear and when.
- **Open questions:** decisions that wait on the owner. Each one leaves the list once decided, and the answer goes where it applies.
- **Done when:** the check that ends the plan, after which the plan and its `TODO.md` line are deleted.

A plan may add sections of its own between Goal and Steps, such as this one and the one above it, to hold what the steps need.

## Steps

- [x] Settle the template.
- [x] Rewrite this plan to the template, and move the planning skill to the top of `TODO.md`.
- [x] Write `claude/skills/planning/SKILL.md`, with the template in `references/template.md`, and install it.
- [x] Add the rule for `TODO.md` and `docs/plans/` to the global `CLAUDE.md`, in two lines, pointing to the skill for the rest.
- [x] Add the skill to the README's file table and skills list.
- [x] Have plans list the docs they make stale, and close only once those are updated.
- [x] Have plans list the people to tell, and when.
- [x] Widen that list to tickets, email threads, and chat channels.
- [x] Run the skill on the [Markdown audit plan](markdown-audit.md) to fit it to the template.
- [x] Fit the other plans to the template, one commit each.
- [ ] In a new session, ask Claude to plan a piece of work, and check it writes the plan file and the `TODO.md` line unprompted.

## Docs to update

- [x] `claude/CLAUDE.md`: point to the skill from a "Plans" section.
- [x] `README.md`: list the skill in the file table and the skills list.
- [x] `claude/skills/planning/`: move this plan's "How a repo holds its plans" and "The plan template" there, if they say anything the skill does not.

## Updates to send

None: the skill runs only on this repo's owner's machines, and no ticket tracks it.

## Done when

Every file in `docs/plans/` follows the template, and asking Claude to plan a piece of work produces a plan file and a `TODO.md` line without further instruction.
