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
- **Open questions:** decisions that wait on the owner. Each one leaves the list once decided, and the answer goes where it applies.
- **Done when:** the check that ends the plan, after which the plan and its `TODO.md` line are deleted.

A plan may add sections of its own between Goal and Steps, such as this one and the one above it, to hold what the steps need.

## Steps

- [x] Settle the template.
- [x] Rewrite this plan to the template, and move the planning skill to the top of `TODO.md`.
- [x] Write `claude/skills/planning/SKILL.md`, with the template in `references/template.md`, and install it.
- [ ] Add the rule for `TODO.md` and `docs/plans/` to the global `CLAUDE.md`, in two lines, pointing to the skill for the rest.
- [ ] Add the skill to the README's file table and skills list.
- [ ] Run the skill on the [Markdown audit plan](markdown-audit.md) to fit it to the template.
- [ ] Fit the other plans to the template, one commit each.

## Open questions

- Whether the [Markdown audit skill](markdown-audit.md) checks that a repo follows this layout, or leaves that to this skill. Leaning: the audit checks it and links here, so the rule lives in one place.

## Done when

Every file in `docs/plans/` follows the template, and asking Claude to plan a piece of work produces a plan file and a `TODO.md` line without further instruction.
