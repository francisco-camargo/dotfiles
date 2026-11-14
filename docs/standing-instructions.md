# Standing instructions

`~/.claude/CLAUDE.md` holds standing instructions Claude reads at the start of every session in every project: the home for preferences I would otherwise explain again and again.
The repo keeps it as `claude/CLAUDE.md`, and `install.sh` installs it like everything else.
The entries arrived two ways: some I had said once already and would otherwise say again, and some are standards set up front.

## The bug that makes the case for it

This machine gives Claude two shell tools, PowerShell and Bash, and their multi-line string syntax is not interchangeable.
PowerShell uses a here-string:

```powershell
git commit -m @'
subject line
'@
```

Bash uses a heredoc:

```bash
git commit -F - <<'MSG'
subject line
MSG
```

Feed the PowerShell form to the Bash tool and nothing errors.
Bash has no idea `@'` is meant to open anything, so it passes the `@` through as an ordinary character.
The commit succeeds, with `@` and a space glued to the front of the subject and a stray `@` alone on the last line of the body.
Nothing complains, the tool reports success, and it looks fine until someone reads the log.
The repair is an amend.

That happened here while making commit `116e4ff`, and the mistake recurs rather than teaching itself: neither tool signals the mismatch, and any setup that exposes both shells invites it.

A global `CLAUDE.md` is for this.
It holds standing facts about the environment that need saying once, somewhere lasting, rather than one-off errors:

> When a session exposes both a PowerShell tool and a Bash tool, their syntaxes do not mix.
>
> In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
> The PowerShell here-string `@'...'@` is not Bash syntax and does not fail: Bash passes the `@` through as an ordinary character, silently embedding it in the text.
>
> In the PowerShell tool, write `A; if ($?) { B }` in place of `A && B`: `&&` and `||` are parse errors in Windows PowerShell 5.1.

The general rule: anything corrected in two different sessions is a candidate.
A correction made only in a conversation ends with it.

## The preference that makes the same case

The wrapping convention is not a bug, which is the point: the file is for anything I would otherwise explain again, and preferences qualify.
Prose here was hard-wrapped to eighty columns, which splits sentences across lines and makes a one-word edit reflow every line after it: the diff reports a paragraph changed when a word did.
The convention that fixes it is one sentence per line, breaking at sentence boundaries only.
Markdown joins the lines back into a paragraph when rendered, so the output is identical and only the diffs improve.

Left in a conversation, that preference lasts until the conversation ends, and the next session goes back to wrapping at eighty.
Written down here, it holds in every repo, including ones that have never heard of it.

I wrote the README in the old style and converted it in one pass, as the rule asks: a whole-file change of its own rather than a paragraph quietly reflowed while editing something else.

## The entry chosen rather than corrected

Orwell's six rules from *Politics and the English Language* are in there too.
Where the wrapping rule governs the line breaks, these govern the words: cut what can be cut, prefer the short word, prefer the active, and skip the jargon when a plain word carries the same meaning.
His sixth rule, to break any of them sooner than say anything barbarous, limits the other five, and that matters because a style rule applied past the point of sense costs more than it saves.

That entry arrived differently from the ones above.
Nothing went wrong first: no mangled commit, no paragraph reflowed for one word.
It is a standard set up front, which is the other fair way in.
The bar is not only "this has gone wrong twice"; it is also "this is general and lasting enough to say before it costs anything".
What stays out is the preference that applies to one file, or the rule that would surprise a reader six months from now.

## Instructions are not enforcement

This approach has a limit.
`CLAUDE.md` is advice the model reads, not a rule the machine applies: it lowers the odds and does not remove them.
The `PreToolUse` hook that gates commits could enforce this one: match `@'` in a Bash tool command and refuse it, the same way the gate stops an unapproved commit.
If the written instruction proves not enough, that is the next step, rather than wording it more forcefully.

## One caveat on contents

A global `CLAUDE.md` gets committed and pushed like everything else here, so [Security](security.md) applies to it in full.
It also invites machine specifics: absolute paths, host names, which drive holds what.
Keep it to preferences and conventions, and it stays portable to the next machine.

## What belongs here, and what belongs in a skill

Claude reads everything in this file at the start of every session in every project, whether or not the session touches the subject.
While it stays short that costs nothing.
A long guide would cost something every time, including in sessions that never write a word of prose.

A skill is the other half of the pair.
It installs to `~/.claude/skills/` and is available everywhere, like this file, but it loads only when the work matches its description.
So the choice is not where the instructions live, since both are global, but when they are paid for.

The test: instructions that must shape work nobody thought to ask about, such as a commit message, a code comment, or a reply in the session, have to be always on and belong here.
Instructions that matter only for a particular kind of task can be ten times longer as a skill and cost nothing the rest of the time.

Writing style is the worked example, not the whole of it.
Orwell's six rules apply to every sentence produced in any session, so they belong in this file.
A longer style guide, with examples, before and after pairs, and a checklist, would not, and would sit better as a `writing-style` skill that this file points at.

The same split applies to anything else that grows past a few lines: review checklists, commit message conventions, a house style for diagrams.
The test is the same each time, and [Split standing instructions between CLAUDE.md and skills](../plans/standing-instructions-split.md) records what is left to decide.
