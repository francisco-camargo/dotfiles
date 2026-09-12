# dotfiles

Configuration files kept in one place so every machine behaves the same.

## Intent

Why this repo exists, in my own words — for anyone picking up work here, Claude in a future session included.

I am exploring dotfiles because I want to solve a problem **once**.
Not once per repo, and not once per machine.
When something takes real thought to work out, I want the result to still be there the next time I hit it — in a different project, or on a different computer — rather than re-derived from scratch or half-remembered.

That is the lens I want applied to work here.
The question about any fix is not only "does this work" but "where does this belong so it keeps working elsewhere":

- A fix that only helps in the repo I happen to be sitting in is a fix I will have to make again. Prefer the general form.
- A fix that only helps on this machine is worse, because I will not notice it is missing on the next one. Prefer the portable form.
- A solution I have to remember to apply is the weakest kind. Prefer one the machine applies on its own.

**Claude, when we work here:** default to generalizing.
If something we are fixing in another repo would help in every repo, or on every machine, say so and propose lifting it here instead of solving it locally and moving on.
Treat a local one-off as a deliberate choice needing a reason, not the default.
And when this repo's own mechanics undermine the goal — copies drifting out of sync, two sources of truth for one skill — treat that as a real problem rather than a papercut, because it defeats the entire point of the repo.

The counterweight: scope grows when repetition justifies it, not in anticipation.
Something earns a place here once I have hit it twice — not the first time I imagine I might.
Generalize what has actually recurred; leave the rest alone.

## Introduction

### What dotfiles are

Most programs store their settings as plain files in your home directory.
On Unix these traditionally start with a dot — `.bashrc`, `.gitconfig`, `.vimrc` — which hides them from a normal `ls`.
That is where the name *dotfiles* comes from.
`~/.claude/` is the same convention: the dot is on the directory, and `settings.json` sits inside it.

### The problem they solve

Left alone, that config has three failure modes:

1. **It is scattered and untracked.** You change a setting, it works, and six months later you cannot recall what you changed or why. There is no `git log` for a home directory.
2. **It drifts between machines.** Laptop and desktop slowly diverge, and you only notice when something behaves differently on one of them.
3. **It is lost on reinstall.** A new machine means re-deriving everything from memory.

### The inversion

A dotfiles repo makes the git repo the real location and the home directory a set of pointers.
`~/.claude/settings.json` becomes a **symlink** — a file that is really just a pointer to another path — aimed at `claude/settings.json` in this repo.
Both paths are then the same file: edit through either one and you have edited the repo.
Setting that up is all `install.sh` does.

The payoff is the ordinary git workflow applied to config:

- **One source of truth.** No hunting for which copy is the current one.
- **A history with reasons.** Every change is a commit, so `git log` answers "why is this set this way", and `git revert` undoes one that turned out badly.
- **Reproducible machines.** `git clone`, then `./install.sh`, and the machine behaves like the others. No hand-copying, no half-configured laptop.
- **Config that is readable.** The repo is also documentation. The sections below explain what each piece does, so the setup can be understood later rather than reverse-engineered.

### What is here today

Three things: `claude/settings.json`, holding the model choice, the three-layer [git approval gate](#the-git-approval-gate), the [sed gate](#the-sed-gate), and the [uv gate](#the-uv-gate); `claude/CLAUDE.md`, the [standing instructions](#a-global-claudemd) read at the start of every session; and the [`md-to-pdf` skill](#the-md-to-pdf-skill).
Small scope on purpose — it starts with what actually gets used and grows when repetition justifies it.
[What else could live here](#what-else-could-live-here) lists the likely additions.

### The working loop

Edit a file in this repo, commit it, and on any other machine `git pull`.
With symlinks the change is live immediately.

On this Windows machine it is not, because Developer Mode is off and `install.sh` falls back to copying — and copies do not track edits.
Until that changes, re-run `./install.sh` after editing anything here, or the change stays in the repo and never reaches `~/.claude/`.
Details in [Symlinks on Windows](#symlinks-on-windows).

## Platform support

`bash` and `git` are the only requirements.
There is nothing here that ties the repo to one operating system:

- **macOS and Linux** work as-is, and get real symlinks by default — no Developer Mode step, so the [working loop](#the-working-loop) above is the live-edit one rather than the re-run-`install.sh` one.
- **Windows** works through Git Bash. `.gitattributes` normalizes line endings to LF so the scripts stay executable everywhere.

The Windows-specific pieces are inert elsewhere rather than broken: the `PowerShell(...)` entries in `permissions.ask` name a tool that does not exist on macOS, `md2pdf.sh` guards its `cygpath` calls behind `command -v`, and its browser search list already includes the `/Applications/` paths alongside the `C:\Program Files\` ones.

Where the sections below say "this Windows machine", they are reporting where the config happens to run today, not stating a requirement.

## Install on a new machine

```bash
git clone https://github.com/francisco-camargo/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./install.sh
```

Then restart Claude Code, or open `/hooks` once, so it reloads settings.

`install.sh` symlinks `claude/settings.json`, `claude/CLAUDE.md`, and `claude/skills/md-to-pdf` into `~/.claude/`.
Anything already there is moved into `~/.claude/backups/` first — nothing is silently overwritten.
Use `--dry-run` to preview, `--copy` to force copies instead of links.

On a machine that has been used before this repo reaches it, read the next section first.

### `install.sh` replaces `settings.json` wholesale

`install.sh` treats all three items the same way: back up what is there, then put the repo's version in its place.
That is right for `CLAUDE.md` and the skill, which are whole files this repo owns.
It is wrong for `settings.json`, because there is only one user settings file and everything user-level has to share it.

Claude Code reads settings in this order, highest first: managed, command line, `.claude/settings.local.json`, `.claude/settings.json`, `~/.claude/settings.json`.
The `settings.local.json` layer is per project, not per user, and there is no include or extends mechanism.
So an existing `~/.claude/settings.json` is not merged with this repo's — it is moved into `~/.claude/backups/` and replaced.

What that costs someone who already had one: their model choice, their `statusLine`, their `env` block, their MCP servers, and every `permissions.allow` rule they built up answering "Yes, and don't ask again".
Nothing is destroyed, but getting it back means merging two JSON files by hand, and the symptom is Claude Code asking again about commands it had stopped asking about a year ago.

This costs nothing on a machine already running this repo's settings, which is why it went unnoticed.
It is a real hazard for anyone else, and for a future machine of mine that has a history before the first `./install.sh`.
Until the guard lands — [Merge `settings.json` instead of replacing it](#merge-settingsjson-instead-of-replacing-it) — copy `~/.claude/settings.json` somewhere safe first, then merge the pieces back by hand afterwards.

### Symlinks on Windows

Windows only allows symlinks with Developer Mode on (Settings → System → For developers) or an elevated shell.
Without it the script notices, says so, and copies instead.

Git Bash adds a second requirement that is easy to miss.
Its `ln -s` copies the file and exits 0 unless `MSYS=winsymlinks:nativestrict` is set, so no link is attempted and nothing reports a problem — turning Developer Mode on by itself would not have changed the outcome.
`install.sh` now sets that variable on the `ln` call, which makes the OS refusal visible for the `-L` check to catch.
The variable means nothing to `ln` on macOS or Linux.

As of this writing the fallback is still what happens on the main Windows machine.
Developer Mode is off and the shell is not elevated, so a native symlink fails with "operation not permitted" and `install.sh` copies.
Copies work fine, but they do not track edits: after changing anything in this repo, re-run `./install.sh` to push the change back out.
Turn Developer Mode on and you get real symlinks, and edits propagate on their own.

### Copies drift both ways

The copy fallback has a second failure mode, and it is easier to hit than the first.
Because `~/.claude/skills/md-to-pdf/` is an ordinary directory and not a link, editing a skill in place — which is what Claude does when asked to change a global skill — leaves this repo clean.
`git status` reports nothing, so the change looks like it was never made, and the next `./install.sh` quietly replaces it with the repo's older copy.
The overwritten directory does get moved into `~/.claude/backups/`, so the work is recoverable, but only if you notice in time to go looking for it.

This has already happened once.
An `h4` rule added to `print.css` lived only in `~/.claude`, while the repo picked up two commits the live copy never saw.
Both sides had edits the other did not.

Until it is fixed, the rule is: edit files in this repo, never in `~/.claude`, then re-run `./install.sh`.
And before running the installer, diff the two trees so an in-place edit does not get thrown away:

```bash
diff -r claude/skills/md-to-pdf ~/.claude/skills/md-to-pdf
```

**To deal with next.** Both halves are tracked under [Open items](#open-items): turning on Developer Mode, which ends the copying, and a `--force` guard for machines where Developer Mode is not on offer.
A copy-mode install should not be able to silently destroy work, and right now it can.

### A backup is not always inert

`install.sh` used to leave backups beside the original, as `<name>.bak.<timestamp>`.
Harmless for a file, wrong for a skill.
Claude Code loads every directory under `~/.claude/skills/` as a skill, so `md-to-pdf.bak.20260904-012854` was not sitting quietly on disk — it was a second copy of the skill offered to the model next to the real one, carrying an older description of when to use it.
Every reinstall added one more.

Backups now collect in `~/.claude/backups/`, which nothing loads.
The general point is worth keeping for anything else installed here: `~/.claude` is not a plain directory, and where a file sits decides whether it runs.

### Settings only load at startup

Claude Code reads `~/.claude/settings.json` when a session starts.
Installing or editing settings mid-session does nothing until the config reloads — a session that was already running keeps the old rules, including no git approval gate.
Restart Claude Code, or open `/hooks` once, before assuming a change is live.

To confirm the gate is actually working, ask Claude to make a trivial commit.
You should get an approval prompt.
If the commit just goes through, the settings have not reloaded yet.

## What's here

| Path | Goes to | What it is |
| --- | --- | --- |
| `claude/settings.json` | `~/.claude/settings.json` | Model choice, the git approval gate, and the sed and uv gates below |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Standing instructions for every session, everywhere |
| `claude/skills/md-to-pdf/` | `~/.claude/skills/md-to-pdf/` | Renders a Markdown file to a print-ready PDF |

## The git approval gate

`claude/settings.json` requires explicit approval before Claude runs `git commit` or `git push`.
Three layers, because the first two have gaps:

1. **`hooks.PreToolUse`** — a sed+grep command that reads the command out of the tool payload and forces an approval prompt when it matches `git[^;&|]{0,60}(commit|push)`. This is the layer that matters: it catches compound commands like `cd /repo && git commit`, which the prefix-matching permission rules below miss entirely.
2. **`permissions.ask`** — rules for `Bash(git commit:*)`, `Bash(git push:*)` and the PowerShell equivalents. `ask` rules beat `allow` rules, so a project cannot grant itself permission later.
3. **`autoMode.soft_deny`** — stops auto mode's classifier from self-approving a commit, and spells out that "save this" or "version this" is not authorization.

The hook uses only `sed` and `grep` — no `jq`, `node`, or `python`, none of which are reliably installed.
Keep it that way, or it will silently stop firing on a machine that lacks the dependency.

To tighten it from "prompt me" to "never, I'll run git myself", move the entries from `permissions.ask` to `permissions.deny`.

## The sed gate

The second `PreToolUse` hook denies `sed` edits outright.
Unlike the git gate it does not prompt, because there is no case where the answer is yes.

sed rewrites a file by regex, and code is full of characters a regex reads as syntax — `.`, `*`, `[`, `$`, `/`.
A pattern that looks literal quietly matches more than it says.
`s/old/new/g` then replaces every match on every line rather than the one that was meant, `-i` writes the result straight over the file, and the command exits 0 either way.
Run by hand that is survivable, because you read the diff before moving on.
Run as one step in a longer task it is not: the mangled line becomes the base for the next several edits, and by the time it surfaces the diff is hard to untangle.

The hook denies a sed invocation carrying `-i`, `--in-place`, or an `s///` substitution.
It leaves `sed -n '1,50p' file` alone, so paging a file still works — and so does the git gate above, which is itself a `sed -n 's///p'` pipeline.
The refusal names the alternatives, so the response is to use the `Edit` tool or write a short script, not to look for a way around the hook.

Two details that took a try to get right, and are worth keeping if this is ever edited:

**It trims the payload before matching.**
The hook reads the command out of the tool payload with the same `sed -n 's/.*"command"...//p'` extraction as the git gate.
That extraction is greedy in one direction only: it strips everything before the command but leaves the rest of the JSON — including the `description` field — on the line.
Any description containing `files,` or `functions,` then reads as an `s,` substitution and blocks an innocent command.
The second `sed 's/"[,}].*$//'` cuts the line at the end of the command value, which is what stops it.

To drop the gate, delete the second entry in `hooks.PreToolUse`.
To make it a prompt rather than a refusal, change `"permissionDecision": "deny"` to `"ask"`.

## The uv gate

The third `PreToolUse` hook denies a bare `python`, `python3`, or `py`.
Like the sed gate it refuses outright rather than prompting, because the answer never changes: run it through `uv`.

The reason is not taste.
On this machine `python` and `python3` on `PATH` are symlinks to `AppInstallerPythonRedirector.exe` — the Microsoft Store redirector, which opens a Store page rather than running anything.
There is no Python installed outside uv; the only real interpreter is the one under `%APPDATA%\uv\python\`.
So `python script.py` cannot succeed here, and the cost of trying is a wasted turn spent reading a failure that looks like a missing file rather than a missing interpreter.

The hook matches those names in command position — at the start, or after `;`, `&&`, `||`, `|`, or `(`.
That anchoring is what makes it worth a hook rather than a permission rule, for the same reason the git gate needs one: it catches `cd src && python app.py`, which prefix matching misses.

It deliberately leaves alone anything under `uv run`, including `uv run python -c ...`, where `python` is an argument rather than the command.
It also leaves an explicit interpreter path such as `.venv/Scripts/python.exe` alone, which is a deliberate choice rather than the habit being corrected, and `python` used as an argument or inside a filename — `which python`, `grep -r python src/`, `cat python_notes.md`.
`pytest` is untouched too, despite sharing its first two letters with the `py` launcher.

The refusal names the `uv` forms to use, so the correction arrives in the same turn and the next attempt is `uv run` rather than a hunt for the interpreter.

One detail worth keeping if this is ever edited: the alternation `\|\|` and the escaped `\.` have to survive being written into JSON as `\\|\\|` and `\\.`.
Get that wrong and the pattern still parses, still exits 0, and quietly matches nothing.
Test the string pulled back out of `settings.json`, not the one typed into the shell.

`pip` is not covered.
`pip install` reaches for the same missing interpreter, and `uv pip` or `uv add` is the replacement — the omission is scope, not a finding that it is safe.

To drop the gate, delete the third entry in `hooks.PreToolUse`.
To make it a prompt rather than a refusal, change `"permissionDecision": "deny"` to `"ask"`.

## The md-to-pdf skill

```bash
~/.claude/skills/md-to-pdf/scripts/md2pdf.sh some-document.md
```

Converts Markdown to HTML with a small awk script, inlines `assets/print.css`, and prints it with headless Chrome or Edge.
No pandoc or node needed.
Layout, including page breaks and repeated table headers, is all in the stylesheet.
See `claude/skills/md-to-pdf/SKILL.md` for details.

### Skill scope, and duplicates

A skill installed here lands in `~/.claude/skills/` and is available in every project.
A skill committed to a repo's own `.claude/skills/` is available only in that repo.
When the same skill name exists in both, the project copy wins.

`md-to-pdf` currently exists in both places — here, and in another repo's own `.claude/skills/`.
The copies are identical so nothing misbehaves, but there are two sources of truth.
Worth deleting the project copy at some point and letting this repo own it.

## A global CLAUDE.md

`~/.claude/CLAUDE.md` holds standing instructions Claude reads at the start of every session in every project — the home for preferences that otherwise get re-explained, and then re-explained again.
It is now in the repo as `claude/CLAUDE.md` and installed like everything else.
Three entries so far: two that had to be said once already and would otherwise have to be said again, and one standard set up front.

### The bug that makes the case for it

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
The commit succeeds — with `@ ` glued to the front of the subject and a stray `@` alone on the last line of the body.
Nothing complains, the tool reports success, and it looks fine until the log is read back.
The repair is an amend.

That happened here while making commit `116e4ff`, and it is the kind of mistake that recurs rather than teaching itself: neither tool signals the mismatch, and the confusion is a permanent property of a setup that exposes both shells.

Which is precisely what a global `CLAUDE.md` is for.
Not one-off errors, but standing facts about this environment that need saying once, somewhere durable:

> This machine exposes both a PowerShell tool and a Bash tool, and their syntaxes do not mix.
> In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting — the PowerShell here-string `@'...'@` is not Bash syntax and will silently embed literal `@` characters rather than failing.
> In the PowerShell tool the reverse holds, and `&&` and `||` are parse errors in Windows PowerShell 5.1.

The general shape is worth noticing: anything corrected twice in two different sessions is a candidate.
A correction that only lives in one conversation is gone when that conversation ends.

### The preference that makes the same case

The second entry is not a bug, which is the point — the file is for anything that would otherwise be re-explained, and preferences qualify.
Prose here was hard-wrapped to eighty columns, which splits sentences across lines and makes a one-word edit reflow every line after it: the diff reports a paragraph changed when a word did.
The convention that fixes it is one sentence per line, breaking at sentence boundaries only.
Markdown joins the lines back into a paragraph when rendered, so the output is identical and only the diffs improve.

Left in a conversation, that preference lasts until the conversation ends and the next session goes back to wrapping at eighty.
Written down here, it holds in every repo, including ones that have never heard of it.

This README was written in the old style and converted in one pass, which is what the rule asks for: a whole-file change of its own rather than a paragraph quietly reflowed while editing something else.

### The third entry, chosen rather than corrected

Orwell's six rules from *Politics and the English Language* are the third entry.
Where the wrapping rule governs the line breaks, these govern the words: cut what can be cut, prefer the short word, prefer the active, and skip the jargon when a plain word carries the same meaning.
His sixth rule keeps the other five honest — break any of them sooner than say something clumsy — which matters, because a style rule applied past the point of sense costs more than it saves.

That entry arrived differently from the first two.
Nothing went wrong first: no mangled commit, no paragraph reflowed for one word.
It is a standard set up front, which is the second legitimate way in.
The bar is not only "this has gone wrong twice" — it is also "this is general and durable enough to be worth saying before it costs anything."
What stays out is the preference that applies to one file, or the rule that would read as a surprise six months from now.

### Instructions are not enforcement

Worth being honest about the ceiling.
`CLAUDE.md` is advice the model reads, not a rule the machine applies — it lowers the odds, it does not remove them.
The `PreToolUse` hook that already gates commits could genuinely enforce this one: match `@'` in a Bash tool command and refuse it, the same way the gate stops an unapproved commit.
If the written instruction proves not to be enough, that is the escalation rather than wording it more emphatically.

### One caveat on contents

A global `CLAUDE.md` gets committed and pushed like everything else here, so [Security](#security) applies to it in full.
It is also a natural place to drift into recording machine specifics — absolute paths, host names, which drive holds what.
Keep it to preferences and conventions, and it stays portable to the next machine.

### What belongs here, and what belongs in a skill

Everything in this file is read at the start of every session in every project, whether or not that session touches the subject.
At 46 lines it costs nothing.
A long guide would cost something every time, including in the sessions that never write a word of prose.

A skill is the other half of the pair.
It installs to `~/.claude/skills/` and is available everywhere, exactly like this file, but it loads only when the work matches its description.
So the choice is not where the instructions live — both are global — but when they are paid for.

The test: instructions that must shape work nobody thought to ask about, such as a commit message, a code comment, or a reply in the session, have to be always-on and belong here.
Instructions that only matter once someone sits down to a particular kind of task can be ten times longer as a skill and cost nothing the rest of the time.

Writing style is the worked example rather than the whole of it.
Orwell's six rules apply to every sentence produced in any session, so they belong in this file.
A longer style guide — examples, before and after pairs, a checklist — would not, and would sit better as a `writing-style` skill that this file points at.

The same split is waiting for anything else that grows past a few lines: review checklists, commit message conventions, a house style for diagrams.
The test is the same each time, and [Split standing instructions between CLAUDE.md and skills](#split-standing-instructions-between-claudemd-and-skills) records what is left to decide.

## Security

The repo is private, but private is not the same as safe.
It gets cloned to every machine, sits in plain text in every backup, and is readable by anything running as you.
Treat it as a file that leaks eventually and decide what goes in it on that basis.

### What is in here today

Nothing sensitive.
`settings.json` holds a model name and permission rules, `install.sh` holds paths, the skill is shell, awk, and CSS.
Searching the entire history — not just the current files — for key, token, and password patterns turns up only this README talking about them.
That is the state to preserve, and it is worth re-checking whenever the repo grows.

### The directory this installs into is full of secrets

This is the real hazard, and it is not obvious.
`~/.claude/` contains far more than `settings.json`:

| Path | What it holds |
| --- | --- |
| `~/.claude/.credentials.json` | The Claude Code auth token |
| `~/.claude.json` | OAuth account, user and machine IDs, per-project history |
| `~/.claude/projects/` | Full transcripts of every session, in every repo |
| `~/.claude/shell-snapshots/`, `session-env/` | Captured shell state, including exported environment variables |
| `~/.claude/file-history/`, `backups/` | Copies of files as they were edited during sessions |

None of that belongs in git.
Transcripts alone are the whole content of private repos plus anything read or pasted during a session.

The failure mode is not typing a password into `settings.json` — nobody does that.
It is broadening `install.sh` to sync "all of `~/.claude`" and sweeping the rest up with it.
So: **the install stays an explicit allowlist**.
`install.sh` names each file it places, one `place` line at a time, and never walks the directory.
Adding config means adding a line, not widening a glob.

### Commit the reference, not the secret

`settings.json` supports an `env` block, which is exactly where someone would paste an `ANTHROPIC_API_KEY` to make something work.
Don't.
Set the variable in the shell profile or the OS environment and let the config refer to it by name.
The same rule covers every future addition: API keys, tokens, `~/.ssh/` private keys, `.env` files, anything with a password in it.

`.gitignore` already excludes `*.bak`, which is where `install.sh` parks whatever it replaced — those backups are copies of real local config and should never be committed.

### Git history does not forget

If a secret is ever committed, deleting it in a later commit does not remove it.
It stays in every clone, in every fork, and on GitHub's servers.
The fix, in order:

1. **Rotate the credential.** Assume it is burned. This is the step that actually matters.
2. Rewrite the history with `git filter-repo` and force-push, as cleanup.

Same reason to audit the full history rather than the working tree before ever flipping this repo public — going public publishes every commit ever made, not the current state.

### This repo runs code on every machine that installs it

`install.sh` is a script you execute.
More significantly, the `PreToolUse` hooks in `settings.json` run a shell command on *every* Bash and PowerShell tool call on every machine that has installed it.
Whatever lands in this repo, runs.

That makes write access to this repo equivalent to code execution on all your machines:

- Keep 2FA on the GitHub account.
- Read the diff before `git pull && ./install.sh` on another machine, the same way you would for any script handed to you.
- If this repo is ever shared or made public, treat a pull request against it as a change to a security-sensitive script, not a config tweak.

### A guardrail, if it earns its keep

A pre-commit hook running `gitleaks` or `trufflehog` blocks the accidental commit before it happens.
Overkill at the current size — there is nothing here to catch.
Worth adding once the repo grows to shell profiles and git config, which is where credentials genuinely creep in: a remote URL with a token embedded in it, an alias carrying a password, an exported key in `.bashrc`.

That "once" has arrived: see [Before this repo goes public](#before-this-repo-goes-public).

## Before this repo goes public

Going public is a one-way door.
A private repo nobody has fetched can still be rewritten; a public one cannot be un-published, because clones and forks are outside your control ([Git history does not forget](#git-history-does-not-forget)).
Everything below wants deciding first rather than afterwards.

### The leak that is actually likely

Not a password in `settings.json`.
Two paths that are real:

`~/.claude/.credentials.json` holds the auth token and sits in the directory this repo mirrors.
Nothing copies it today, and the allowlist rule under [The directory this installs into is full of secrets](#the-directory-this-installs-into-is-full-of-secrets) is what keeps that true.
But [What else could live here](#what-else-could-live-here) runs to shell profiles, global git config, VS Code settings, and a bootstrap script, and any bulk copy out of `~/.claude` on the way there takes the token with it.

Those additions are themselves where credentials hide: a remote URL with a token in `.gitconfig`, a credential helper, extension tokens in VS Code's own `settings.json`, an export in `.bashrc`.
The section above judged a scanner overkill at the current size.
Going public while growing into exactly those files is the trigger that judgment named.

### Four layers, and what each one misses

| Layer | Catches | Misses | Cost |
| --- | --- | --- | --- |
| GitHub push protection | Recognized credential formats, server side, blocks the push | Passwords, host names, anything without a known token shape | A checkbox |
| Hardened `.gitignore` | Whole files — `.credentials.json`, `.env`, private keys | `git add -f`, and secrets pasted inside tracked files | Ten lines |
| A `pre-commit` hook | Secrets pasted into tracked files, which the two above miss | `--no-verify`, and anyone who never enabled it | Forty lines plus setup |
| `gitleaks` in Actions | The best detection of the four | Runs after the push — on a public repo, after it is already published | A workflow file |

Push protection is the one to reach for first, and it is free.
Secret scanning runs automatically on public repositories at no cost.
Push protection is a separate switch: repository-level is off by default, and an administrator turns it on under Settings → Code security.
It blocks the push and says why.
Anyone with write access can bypass it by giving a reason, which is the right trade when the thing being defended against is an accident rather than an attacker.

The Actions scan is a backstop rather than a gate.
By the time it fires on a public repo, the commit is already published.

### Repo-local hooks, or global, and the trap in the global one

A `pre-commit` hook needs `core.hooksPath`, because `.git/hooks/` is not cloned.

- **Repo-local**, set by `install.sh` from inside this repo. Narrow and safe, and covers only this repo.
- **Global**, pointing at this repo from the global git config. This is the "solve it once, not once per repo" form the [Intent](#intent) section argues for.

The trap is that a global `core.hooksPath` overrides per-repo hooks everywhere.
Any repo shipping its own `pre-commit` quietly stops running it, with nothing to say so.
Repo-local first, then; global is a separate decision that needs an answer to that objection before it is worth taking.

### Already decided: the history keeps the old names

The two references to internal repos are generalized in the working tree.
Both remain in `README.md` throughout the history, and one remains in the commit message of `938f77c`.
Rewriting 26 of 27 commits to hide a repo name was judged not worth losing the history over.

That decision is reversible only up to the moment the repo goes public.
Anyone minded to reconsider should reconsider now.

### The order to do it in

1. **Turn on push protection.** Highest value, and the only item here that no commit can do for you.
2. **Harden `.gitignore`** with the filenames that would actually cost something.
3. **Add the `pre-commit` hook**, `sed` and `grep` only, wired up repo-local by `install.sh`.
4. **Audit the full history once more**, deliberately rather than in passing — the working tree being clean is not the same claim.
5. **Decide on the `gitleaks` workflow** once the local hook has been lived with for a while.

Then the switch.

One more that is not about secrets but shares the deadline.
[This repo runs code on every machine that installs it](#this-repo-runs-code-on-every-machine-that-installs-it), so public means strangers can open pull requests against a script you execute.
Turn on branch protection, and read every proposed change to `install.sh` or the hooks as what it is.

## Open items

Work that is started and unfinished, as opposed to [what else could live here](#what-else-could-live-here), which is speculative.
Each of these is known to be missing, not merely imagined.

### Turn on Developer Mode

The one item that needs a person rather than a commit.
`install.sh` now asks Git Bash for a real symlink instead of letting it copy in silence ([Symlinks on Windows](#symlinks-on-windows)), so the only thing still in the way is the OS.
Developer Mode is off on this machine — `AllowDevelopmentWithoutDevLicense` is unset under `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock` — and the shell is not elevated, so a native link fails with "operation not permitted" and the installer copies instead.

Settings → System → For developers → Developer Mode on, then re-run `./install.sh`.
Turning it on takes an administrator, which is why no session can do it for you.
After that the installed files are the repo files, edits propagate on their own, and the drift below stops being possible.

### Stop a copy-mode install from overwriting newer work

Described in full under [Copies drift both ways](#copies-drift-both-ways).
While the installer copies, a skill edited in place in `~/.claude` is invisible to `git status`, and the next install replaces it with the repo's older version.
Backups make that recoverable, not harmless.
The guard is to refuse a destination whose contents differ from the repo unless passed `--force`.
Developer Mode removes the need on this machine; the guard is what covers a machine where Developer Mode is not on offer.

### Merge `settings.json` instead of replacing it

Described in full under [`install.sh` replaces `settings.json` wholesale](#installsh-replaces-settingsjson-wholesale).
The installer overwrites a file that everything user-level shares, so anyone who already had settings loses them to a backup directory.

A real merge is the wrong fix.
It needs a JSON parser, and the rule that keeps the hooks portable — `sed` and `grep` only, no `jq`, no `node`, no `python` — is the same rule that makes merging JSON inside `install.sh` a bad idea.
A merger written in awk would fail quietly on a nested key, which is the failure this repo keeps trying to design out.

Three smaller pieces instead, in the order they are worth doing:

- **Refuse rather than clobber.** If `~/.claude/settings.json` exists and is not already this repo's, skip it, print the block to paste, and carry on installing `CLAUDE.md` and the skill. Roughly fifteen lines, no JSON parsing, and it fails loudly instead of silently.
- **Hand other people the project-level route.** Hook entries merge across settings levels rather than replacing each other, so all three gates work committed to a shared project's `.claude/settings.json`. Everyone who clones that repo gets the gates, and no home directory is touched.
- **Move the hook bodies into scripts.** `claude/hooks/git-gate.sh`, `claude/hooks/sed-gate.sh`, and `claude/hooks/uv-gate.sh`, with `settings.json` holding stanzas that call them. It does not fix the merge, but it shrinks the block a person has to paste and makes each hook testable on its own rather than by pulling a string back out of JSON — which the uv gate's escaping already argues for.

One thing to settle at the same time, because it arrives with Developer Mode rather than with a coworker.
Claude Code writes `~/.claude/settings.json` itself, the first time you change a `/config` option stored in user settings — the theme, for instance.
Once that file is a symlink into this repo, those writes land in the working tree: changing the theme becomes an uncommitted diff here, and can conflict on the next `git pull`.
Keeping `settings.json` a copy while the other two are links is the simple answer.

### Split standing instructions between CLAUDE.md and skills

Described under [What belongs here, and what belongs in a skill](#what-belongs-here-and-what-belongs-in-a-skill).

Nothing is wrong today.
`CLAUDE.md` is 46 lines and every entry in it earns being read every session.
The decision arrives when the first set of instructions outgrows that, and a full writing style guide is the likely first case — with review checklists, commit conventions, and diagram style queued behind it.

Three things to settle when it does:

- Where the line falls: a short core here, the long form in a skill, and this file pointing at it.
- Whether a skill's `description` can trigger reliably for prose work, which is a vaguer trigger than "render this Markdown to PDF".
- Whether the split runs per subject, or one `house-style` skill covers all of it.

### Prune `~/.claude/backups/`

Every install adds a copy of whatever it replaced and nothing removes the old ones.
Harmless while the tree is three small things, and worth a `--keep N` or a date cutoff before the directory turns into somewhere nobody looks.

## What else could live here

Nothing below is set up yet.
This is the list of things worth pulling in as the need comes up, roughly in order of how much repetition each one removes.

### More Claude Code configuration

- **More skills** — anything done twice by hand is a candidate. Skills carry the *when* and *why* alongside the script, which is what makes them worth more than a loose shell script.
- **`~/.claude/agents/`** — subagent definitions, if a specialized reviewer or researcher earns its keep.
- **`~/.claude/commands/`** — custom slash commands for repeated multi-step workflows.
- **More hooks** — the same `PreToolUse` mechanism as the three gates above can auto-format after edits, block writes to protected paths, or log what ran.

### Shared repo scaffolding

Three of my other repos already repeat the same files by hand.
`.gitignore` is in all three; `.gitattributes` with `* text=auto eol=lf` is in two and had to be written twice; `cspell.json` exists in one and will want to exist in the others.

Two ways to stop copying them around:

- **Templates here** plus a small `new-repo.sh` that stamps them into a fresh repo. Simple, and each repo stays self-contained.
- **Global git config** — `core.attributesFile` and `core.excludesFile` point at files in this repo, so the rules apply everywhere without any per-repo file. Nothing to copy, but the rules become invisible to anyone cloning a repo, which matters if the repos are ever shared.

Global git config also carries aliases, `pull.rebase`, `init.defaultBranch`, and the default commit editor.

### Machine setup

- **A bootstrap script** listing what a machine needs — `winget install` or `scoop install` lines for gh, Git, VS Code, a PDF viewer. Turns "set up a new laptop" into one command.
- **Editor settings** — VS Code, covered on its own in [VS Code settings](#vs-code-settings) below.
- **Shell profile** — `.bashrc` for Git Bash, or the PowerShell profile, holding aliases and PATH tweaks.

### VS Code settings

This is the next thing to pull in, so it gets more than a bullet.

The three files worth versioning all live in one directory — `%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux:

- `settings.json` — the bulk of it
- `keybindings.json`
- an extensions list, produced by `code --list-extensions > vscode/extensions.txt` and replayed by looping `code --install-extension` over the file

The first two are ordinary `place()` targets and need only a second destination in `install.sh`, since VS Code does not live under `$HOME`:

```sh
vsdest="${VSCODE_USER_DIR:-$APPDATA/Code/User}"
place "$repo/vscode/settings.json"    "$vsdest/settings.json"
place "$repo/vscode/keybindings.json" "$vsdest/keybindings.json"
```

`$APPDATA` is set inside Git Bash.
The extensions list is the odd one out: it is a script input rather than a symlink target, so it wants its own small `vscode/install-extensions.sh`.

#### The recommendation

Start with `settings.json` alone.
Add keybindings once there are any worth keeping, and the extensions list once a second machine exists to replay it onto — that file is the one that pays off only on a fresh install.

Then pick a single source of truth, and let it be the repo.
This matters more for VS Code than it did for Claude Code, because `install.sh` is [copying rather than linking on this machine](#symlinks-on-windows), and VS Code has a settings UI that writes to `%APPDATA%` directly.
Editing settings through that UI while the repo holds the canonical copy produces two files that disagree, and the next `./install.sh` replaces the newer one with the repo's version.
The UI-edited file is not lost — `backup()` moves it to `backup()` moves it into `backups/` first — but recovering a change from a backup in `%APPDATA%` is not a workflow anyone wants twice.
So: edit `vscode/settings.json` in the repo, commit, re-run `./install.sh`.
If a setting gets changed through the UI by reflex — and it will — copy it back into the repo before the next install rather than after.

Enabling Developer Mode and getting real symlinks removes the whole problem, and is the single change that makes versioning editor settings pleasant instead of fiddly.
Worth doing first if you have the option.

Two things to expect.
VS Code settings collect absolute paths — `python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts that exist on one machine — and those are exactly what [Per-machine differences](#per-machine-differences) is about; strip or generalize them on the way in rather than committing a file that only works here.
And some extensions store tokens in `settings.json`, so read [Commit the reference, not the secret](#commit-the-reference-not-the-secret) before the first commit, not after.

### Per-machine differences

The moment a second machine has a genuinely different setting, the single-file approach strains.
The usual fix is a `hosts/<machine-name>/` directory that `install.sh` layers on top of the shared files after placing them, so shared config stays shared and only the differences are duplicated.
Worth doing when the need actually appears, not before.


### Before adding any of this

Shell profiles, git config, and bootstrap scripts are where credentials actually creep in — a remote URL with a token in it, an exported key in `.bashrc`.
Re-read [Security](#security) before pulling any of them in.
