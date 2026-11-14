---
name: planning
description: Write and maintain a repo's plans, one Markdown file per piece of work in docs/plans/, each with a goal, a task list of steps ticked off as commits land, the docs the work must update, the people to tell and when, open questions, and a done-when check, and keep TODO.md a short, ordered list that links to them. Use when asked to plan a piece of work, write or update a plan, tick off progress, split a long TODO list into plans, or decide what to work on next.
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
3. List the docs the work will make stale. Search the repo, and any repo that links into it, for the names of what the work changes: files, commands, settings, headings.
4. List the people to tell, with when. Ask the owner who uses or depends on what changes, since the repo rarely says.
5. Add one line to `TODO.md` under the section that matches its priority, linking to the plan.
6. Present the plan and its steps. The steps are the commit plan: once the owner approves them, take each in turn.

Commit the plan and the `TODO.md` line together, before starting the work, so the plan is on record when the first step lands.

Write a plan only when the work needs more than a line.
A task that fits on one line stays a line in `TODO.md`, with no plan.

## Work through a plan

For each step:

1. Check People to tell for an item due before this step. If one is, stop, remind the owner, and offer a draft of the message. Do not send it yourself unless the owner asks.
2. Do the work.
3. Update the docs the step made stale, and tick their items under Docs to update.
4. Tick the step (`- [x]`) in the plan.
5. Stage the work, the docs, and the ticked plan together, and commit.
6. Check People to tell for an item due once this step lands, and remind the owner as above.

Tick a People to tell item only once the owner says the message went out, in the next commit to the plan.

When the work changes the plan, change the plan in the same commit: add a step it turned up, add a doc it made stale, delete one that no longer applies, move a decided question's answer into the section it affects.

When the last step is ticked, close the plan:

1. Run the done-when check. If it fails, add the steps that would make it pass.
2. Read the plan once more for anything a reader will need after it is deleted, such as a design, a convention, or the reason for a choice. Move each into the doc where it belongs, and add that doc to Docs to update.
3. Once every box is ticked, delete the plan and its `TODO.md` line in one commit.

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
