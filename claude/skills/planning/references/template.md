# The plan template

A plan is one file in `docs/plans/`, named for the work in kebab case, such as `new-machine.md`.

```markdown
# Plan: <the work, in a few words>

## Goal

<One or two sentences: what exists or works once this is done.>

## Why

<Only when the goal does not make the reason plain.>

## <Sections of the plan's own, as many as the steps need>

## Steps

- [ ] <A step about the size of one commit, in the imperative.>
- [ ] <The next step.>

## Docs to update

- [ ] <A file the work makes stale or incomplete>: <what it should say once the work lands.>

## Open questions

- <A decision that waits on the owner, with the option you lean towards.>

## Done when

<The check that ends the plan.>
```

## What each section holds

### Goal

The outcome, not the activity.
"Write a skill that audits a repo's Markdown" beats "Look into Markdown auditing".
A reader who stops after the goal knows what the plan is for.

### Why

The reason, when a reader could ask "why bother?" after the goal.
Leave the section out when the goal answers that.

### The plan's own sections

What the steps need: a design, a comparison of options, the rules a skill will follow.
Give each a heading that names its subject.
Keep the case for a decision short; the decision itself is what the steps rely on.

### Steps

A Markdown task list, in the order the work happens.
Each step is about one commit, so the list doubles as the commit plan the owner approves.
Tick a step (`- [x]`) in the same commit that completes it, never in a later one.
Add a step when the work turns one up; delete one that stops making sense, rather than ticking it.

### Docs to update

A task list of the files that must change for the repo's docs to match the work: the README, files in `docs/`, a `CLAUDE.md`, a skill, or a page in another repo that links here.
The plan is deleted once done, so anything it decided that a reader will need later goes into one of these files: the design into `docs/`, a convention into `CLAUDE.md`, the reason for a choice into the README or a commit message.
Tick an item in the commit that makes the change, which is usually the commit of the step that made the doc stale.

### Open questions

Decisions that wait on the owner.
Give each the option you lean towards and why, in a clause.
Once decided, remove the question and write the answer into the section or step it affects.
When the list is empty, delete the heading.

### Done when

A check someone can run or read, such as "the skill finds the same problems on commit `0a2d48e` that the hand audit did".
The plan is done when the check passes and every item under Docs to update is ticked.
Then delete the plan and its line in `TODO.md`.
