# Standing instructions

Preferences and conventions that apply in every project on this machine.
Keep this file portable: no absolute paths, host names, or anything else that is true of one computer and not the next.

## Markdown prose

Write one sentence per line.
Break at sentence boundaries only — never mid-sentence, and never to satisfy a column limit.
A paragraph is a run of consecutive sentence lines with a blank line on either side; Markdown joins them back into one paragraph when rendered.

The reason is diff granularity.
Hard wrapping to 80 columns means a one-word edit reflows every line after it, so the diff reports a whole paragraph changed when one word did.
One sentence per line keeps the changed unit equal to the edited unit.

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

Rule 6 is not decoration.
The first five are habits to catch yourself breaking, not a filter that outranks being clear or being accurate.
Where a technical term is the precise word, use it — the target is the jargon reached for out of habit, not the vocabulary the subject actually requires.

### No litotes

Do not state a thing by denying its opposite.
"Not uncommon" means common, "no small feat" means a hard one, "not a bad idea" means a good one.
Say the plain word instead.

Orwell goes after one form of this in the same essay, the "not un-" construction, and prescribes a cure: memorize "A not unblack dog was chasing a not unsmall rabbit across a not ungreen field."
The construction costs the reader a step and delivers a hedge, which is usually why writers reach for it.

The rule targets understatement, not negation.
"This does not work" and "nothing copies it today" are plain negatives and stay as they are.
What goes is the negated opposite standing in for a word that already exists: "not unlike", "not without merit", "it would not be unreasonable to", "this is no accident".

## Shells

This machine exposes both a PowerShell tool and a Bash tool, and their syntaxes do not mix.

In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
The PowerShell here-string `@'...'@` is not Bash syntax and will not fail — Bash passes the `@` through as an ordinary character, silently embedding it in the text.
A commit written that way succeeds with `@ ` glued to the front of the subject and a stray `@` on the last line, and looks fine until the log is read back.

In the PowerShell tool the reverse holds, and `&&` and `||` are parse errors in Windows PowerShell 5.1.

<!-- cspell:ignore unblack unsmall ungreen -->
