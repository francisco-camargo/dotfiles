---
name: planning
description: Write and maintain a repo's plans, one Markdown file per piece of work in docs/plans/, each with a goal, a task list of steps ticked off as commits land, open questions, and a done-when check, and keep TODO.md a short, ordered list that links to them. Use when asked to plan a piece of work, write or update a plan, tick off progress, split a long TODO list into plans, or decide what to work on next.
---

# Plan a repo's work

A repo holds its plans in two places:

- **`TODO.md`** at the root orders the work. Each item is one line, linking to its plan where there is one.
- **`docs/plans/`** holds one file per piece of work that needs more than a line.

The plan says what and how; `TODO.md` says what comes first.
A plan is deleted once its work is done, along with its line in `TODO.md`; git keeps the history.

Every plan follows [the plan template](references/template.md).
Read it before writing or changing a plan.

## Plan a new piece of work

1. Read `TODO.md` and the plans in `docs/plans/`, so the new plan neither repeats one nor contradicts one.
2. Write `docs/plans/<name>.md` from the template. Fill the goal first; if it will not fit in two sentences, the work is more than one plan.
3. Add one line to `TODO.md` under the section that matches its priority, linking to the plan.
4. Present the plan and its steps. The steps are the commit plan: once the owner approves them, take each in turn.

Commit the plan and the `TODO.md` line together, before starting the work, so the plan is on record when the first step lands.

Write a plan only when the work needs more than a line.
A task that fits on one line stays a line in `TODO.md`, with no plan.

## Work through a plan

For each step:

1. Do the work.
2. Tick the step (`- [x]`) in the plan.
3. Stage the work and the ticked plan together, and commit.

When the work changes the plan, change the plan in the same commit: add a step it turned up, delete one that no longer applies, move a decided question's answer into the section it affects.

When the last step is ticked, run the done-when check.
If it passes, delete the plan and its `TODO.md` line in one commit.
If it fails, add the steps that would make it pass.

## Keep `TODO.md` short

`TODO.md` opens with a sentence saying it lists the work ahead in priority order.
Its sections run from most to least urgent; in a repo with none yet, use these:

- **Next:** what to start on, in order.
- **Small tasks:** one-line tasks, done when there is a gap.
- **Later:** planned, but not yet started.
- **Ideas:** not planned; pulled in when a need comes up.

Each item is one line: a link to its plan with a short summary after a colon, or for a small task, the task itself.

When an item has grown past a line, move the extra into a plan:

1. Write the plan from the item's text, fitted to the template.
2. Replace the item with one line linking to the plan.
3. Check links into the moved text, with a search for the old heading's anchor across the repo and any repo that links here, and repoint each.

Splitting a whole `TODO.md` this way is one commit per moved item, or one for the lot if the owner prefers; lay out which before starting.

## Fit an existing plan to the template

Older plans may be essays without a goal, steps, or a done-when line.
Fit one at a time:

- Write the goal from what the plan argues for.
- Turn its recommendations into steps, in order.
- Turn its unsettled choices into open questions.
- Keep its reasoning as the plan's own sections, cut to what the steps need.

Report what you could not place, rather than dropping it.

## Decide what comes next

Read `TODO.md` top down.
Recommend the first item under **Next** unless something blocks it, and say what blocks it.
When the owner reorders the work, move the lines in `TODO.md` and commit that alone.
