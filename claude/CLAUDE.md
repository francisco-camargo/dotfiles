# Standing instructions

Preferences and conventions that apply in every project, on every machine.
Keep this file portable: no absolute paths, host names, or anything else that is true of one computer and not the next.

## Markdown prose

Write one sentence per line.
Break at sentence boundaries only: never mid-sentence, and never to satisfy a column limit.
A paragraph is a run of consecutive sentence lines with a blank line on either side.

Exceptions: list items are one line each regardless of length, and tables and code blocks are left alone.

When editing a file that is already hard-wrapped, match the file rather than converting a paragraph in passing.
Converting is a deliberate, whole-file change.

## Markdown structure

### Headings and lists, not bold titles

Give a document headings and subheadings, and use a list for anything enumerable.
Do not open a paragraph with a bolded phrase standing in for a heading: a heading nests, takes a link, and shows up in the outline.

```markdown
**Where it installs.** Every skill lands in `~/.claude/skills/`.
```

becomes

```markdown
#### Where it installs

Every skill lands in `~/.claude/skills/`.
```

A bold lead-in inside a list item is fine.

### No horizontal rules

Do not separate sections with `---`.
The heading is the separator.

### Headings in sentence case

Capitalize the first word of a heading and proper nouns, nothing else.

### Code blocks name their language

Open every fenced code block with its language, such as `sh`, or `text` for output.

### Link text names the target

Make the link text the name of what it points at, never "here", "this link", or a bare URL.

## Writing style

Follow Orwell's six rules, from *Politics and the English Language*:

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

They apply to everything you write: documentation, commit messages, code comments, and replies in the session.

Rule 6 outranks the other five: clarity and accuracy come first.
Where a technical term is the precise word, use it.

### No litotes

Do not state a thing by denying its opposite.
Say the plain word: "not uncommon" means common, "no small feat" means a hard one, "not a bad idea" means a good one.
Also out: "not unlike", "not without merit", "it would not be unreasonable to", "this is no accident".

Plain negatives stay as they are: "this does not work", "nothing copies it".

### Get to the point

State the thing and stop.
Leave out the case for it unless the reader needs the reason to act, or asks for it.

### Filler words

Cut "just", "simply", "easily", "obviously", "very", "really", "actually".

### No em dashes

Do not use em dashes.
Where one would go, use a comma, colon, semicolon, parentheses, or a new sentence.

### Dates

Write dates as YYYY-MM-DD.

### No details that go stale

Do not restate in prose what a reader could look up: a count of what a directory holds, a file's line count, an entry's position in a list, how many repos do something.

Name things rather than counting them, and describe them by what they are rather than where they sit.

- Prefer "the gates below" to "the three gates below".
- Prefer "this gate denies sed edits" to "the second hook denies sed edits".
- Prefer "while it stays short" to "at sixty lines".

Leave out words that date a sentence: "today", "currently", "now", "new", "recently", "soon".

The test: if the claim went false, what would say so?
A list or table in the same section answers that; nothing answers it for a claim about another file.

Keep these:

- a count that an adjacent list makes plain
- a count that carries an argument
- a fixed outside fact
- an identifier that does not change, such as a commit hash

Links and references by name are fine.

## Code

Comments say why; the code already says what.

Delete dead code rather than commenting it out: git keeps it.

For safety, start a shell script with `#!/usr/bin/env bash` and `set -euo pipefail`.
The script then stops at a failed command, an unset variable, or a failure anywhere in a pipeline, rather than running on in a broken state.

Fix a bug by first writing a test that fails because of it.

## Commits

Commit small and often, rather than collecting a session's work into one commit.
One idea per commit: if the subject needs an "and", it is two commits.

Stage the change, then run `git commit` in the same turn.
Stage in one tool call and commit in the next, never in one command: the user inspects the staged change while the commit prompt waits.
Do not stop to ask first, and do not print the diff: the staged change is there to read, and the user accepts or refuses the commit at the permission prompt on `git commit`.

When a change splits into several commits, lay the whole split out first: every subject, and what goes in each.
The user approves the plan once; after that, stage each piece and put its commit to the prompt in turn.

Stage files by path.
Never `git add -A`, `git add .`, or `git commit -a`: they sweep in scratch files and secrets.

Never amend, rebase, or force-push a commit that has been pushed.

Write the subject in the imperative, under about 50 characters, with no trailing period.

Most commits need no body at all.
Add one only when the subject cannot carry the reason, and hold it to a sentence or two saying why, since the diff already says what.
Wrap a body at 72 characters.

## Pull requests

Title a pull request as you would a commit subject.
The body says why the change exists and how to check it; the diff already says what.

## Replies in the session

Say how you checked a claim, or say that you did not.

## Dotfiles

These instructions come from a dotfiles repo, which holds configuration meant for every machine and every project.
When a fix in any repo would help in every repo or on every machine, say so and propose moving it into the dotfiles repo.
A fix kept local needs a reason.

Before making a fix, decide where it belongs, so it keeps working elsewhere.

- Prefer the general form to a fix for one repo.
- Prefer the portable form to a fix for one machine.
- Prefer a fix the machine applies to one the user must remember.

## Memory

Claude Code's per-project memory sits outside every repo, where nobody sees it in day-to-day work.
Save a fact there only when no visible file can hold it.

Before writing a memory, find the file the fact belongs in, and propose that edit instead:

- A preference for every project, such as one sentence per line, goes in this file.
- A convention for one repo, such as its test command or branch naming, goes in that repo's `CLAUDE.md`.
- A rule that must hold every time, such as asking before `git commit`, goes in a hook or permission rule in `settings.json`.
- A procedure repeated across sessions, such as cutting a release, goes in a skill.
- Unfinished work and next steps go in the repo's TODO list or issue tracker.
- The reason for a decision goes in the commit message, or in the README next to what it explains.
- A pointer to a dashboard, ticket, or outside document goes in the README or `docs/`.

Memory suits what has no such home: context about a repo you cannot commit to, or a fact too private for any file in git.

When you save a memory, say so in the reply and name the file.

## Skills

Before editing a skill under `~/.claude/skills`, read `metadata.author` and `metadata.contributors` in its `SKILL.md` frontmatter.

A skill by a third party is vendored, and an official update overwrites any edit made in place.
Do not fix it there.
Write the fix as a small skill of your own, and have it import the vendored skill's shared modules and scripts by sibling path, such as `../vendored-skill/scripts/`.

Edit a vendored skill in place only when there is a real path to send the change upstream to the author it names.

## Shells

When a session exposes both a PowerShell tool and a Bash tool, their syntaxes do not mix.

In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
The PowerShell here-string `@'...'@` is not Bash syntax and does not fail: Bash passes the `@` through as an ordinary character, silently embedding it in the text.

In the PowerShell tool, write `A; if ($?) { B }` in place of `A && B`: `&&` and `||` are parse errors in Windows PowerShell 5.1.
