# Standing instructions

Preferences and conventions that apply in every project on this machine.
Keep this file portable: no absolute paths, host names, or anything else that is true of one computer and not the next.

## Markdown prose

Write one sentence per line.
Break at sentence boundaries only — never mid-sentence, and never to satisfy a column limit.
A paragraph is a run of consecutive sentence lines with a blank line on either side.

Exceptions: list items are one line each regardless of length, and tables and code blocks are left alone.

When editing a file that is already hard-wrapped, match the file rather than converting a paragraph in passing.
Converting is a deliberate, whole-file change.

## Writing style

Follow Orwell's six rules, from *Politics and the English Language*:

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

They apply to everything written here: documentation, commit messages, code comments, and replies in the session.

Rule 6 outranks the other five: being clear and being accurate come first.
Where a technical term is the precise word, use it.

### No litotes

Do not state a thing by denying its opposite.
Say the plain word: "not uncommon" means common, "no small feat" means a hard one, "not a bad idea" means a good one.
Also out: "not unlike", "not without merit", "it would not be unreasonable to", "this is no accident".

Plain negatives stay as they are: "this does not work", "nothing copies it today".

### No details that go stale

Do not restate in prose what a reader could look up: a count of what a directory holds, a file's line count, an entry's position in a list, how many repos do something.

Name things rather than counting them, and describe them by what they are rather than where they sit.
Prefer "the gates below" to "the three gates below".
Prefer "this gate denies sed edits" to "the second hook denies sed edits".
Prefer "while it stays short" to "at sixty lines".

The test: if the claim went false, what would say so?
A list or table in the same section answers that; nothing answers it for a claim about another file.

Keep a count an adjacent list makes self-evident, a count that carries an argument, a fixed outside fact, and identifiers that do not drift, such as a commit hash.
Links and references by name are fine.

## Commits

Commit small and often.
One idea per commit: if the subject needs an "and", it is two commits.
Commit each piece as it is finished rather than collecting a session's work into one.

Stage a commit, then ask before creating it.
Show the whole `git diff --cached`, and the subject line it will carry, and wait for an answer.
The hooks already hold a commit until it is approved, but what they show is the command and not what is in it, which is what makes approving one worth anything.

When a change splits into several commits, lay the whole split out first: every subject, and what goes in each.
The plan is approved once.
Each commit is then still staged and shown before it is created, so nothing is committed unread.

Write the subject in the imperative, under about 50 characters, with no trailing period.

Most commits need no body at all.
Add one only when the subject cannot carry the reason, and hold it to a sentence or two saying why — the diff already says what.
Wrap a body at 72 characters.

## Shells

This machine exposes both a PowerShell tool and a Bash tool, and their syntaxes do not mix.

In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
The PowerShell here-string `@'...'@` is not Bash syntax and does not fail — Bash passes the `@` through as an ordinary character, silently embedding it in the text.

In the PowerShell tool the reverse holds, and `&&` and `||` are parse errors in Windows PowerShell 5.1.
