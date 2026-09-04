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

## Shells

This machine exposes both a PowerShell tool and a Bash tool, and their syntaxes do not mix.

In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
The PowerShell here-string `@'...'@` is not Bash syntax and will not fail — Bash passes the `@` through as an ordinary character, silently embedding it in the text.
A commit written that way succeeds with `@ ` glued to the front of the subject and a stray `@` on the last line, and looks fine until the log is read back.

In the PowerShell tool the reverse holds, and `&&` and `||` are parse errors in Windows PowerShell 5.1.
