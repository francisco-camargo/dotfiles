# Plan: a skill for planning work

Write a skill that structures plan Markdown files, and keeps a repo's TODO list and its plans in step.

Notes so far; the plan itself is still to write.

## How a repo holds its plans

- Each piece of work that needs more than a line gets a plan, one file per piece of work, in `docs/plans/`.
- `TODO.md` stays short and high level: one line per item, linking to its plan where there is one.
- `TODO.md` orders the work, so it is where to decide what comes next.
- A plan is deleted, or cut down to what remains, once its work is done; git keeps the history.

This repo's `TODO.md` and `docs/plans/` are the first example.

## To decide

- The sections every plan has, such as goal, steps, and open questions.
- How the skill splits a long TODO list into plans, as this repo's was split by hand.
- How it relates to the [Markdown audit skill](markdown-audit.md), which judges how a repo's Markdown files fit together.
