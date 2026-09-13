# dotfiles

Configuration files kept in one place so every machine behaves the same.

## Motivation

This repo holds the configuration I want on every machine and in every project.
Today that is Claude Code: its settings and [hooks](#hooks), the [instructions](#standing-instructions) it reads each session, and its [skills](#skills).
[What's here](#whats-here) lists each file and where it installs.
[Candidates for later](#what-else-could-live-here) are git config, VS Code settings, a shell profile, and the files each repo repeats, such as `.gitignore` and `.gitattributes`.

When I settle how a tool should behave, through a setting, a hook, or a rule for Claude, I want to do it **once**, not once per repo or once per machine.
The hook that makes Claude ask before `git commit` shows the idea: written once here, it holds in every repo on every machine that runs `install.sh`.
`.gitattributes` shows the opposite: I have written it by hand in more than one repo.

## Introduction

### What dotfiles are

Most programs keep their settings in plain files in your home directory.
On Unix the names start with a dot, as in `.bashrc`, `.gitconfig` and `.vimrc`, which hides them from a plain `ls`.
Hence the name *dotfiles*.
`~/.claude/` follows the same convention, with the dot on the directory.

### The problem they solve

Without a repo, such a config file

1. **Has no history.** Six months after changing a setting, you cannot recall what you changed or why.
2. **Drifts between machines.** You notice only when something behaves differently on one of them.
3. **Is lost on reinstall.** A new machine means rebuilding it from memory.

### Symlinks

A dotfiles repo makes the repo the real location, and the home directory a set of links to it.
`~/.claude/settings.json` becomes a **symlink**, a file that points to another path, here `claude/settings.json` in this repo.
Editing either path edits the repo.
`install.sh` creates the links.

That brings git to config:

- **One source of truth.** There is one copy, and it is the current one.
- **A history.** Each change is a commit, so `git log` shows why a setting is what it is, and `git revert` undoes it.
- **Reproducible machines.** `git clone` and `./install.sh` make a new machine behave like the others.
- **Documentation.** The sections below explain what each piece does.

### The working loop

Edit a file here, commit it, and `git pull` on the other machines.
With symlinks, the change takes effect at once.

Windows refuses symlinks to an ordinary user until Developer Mode is on, so `install.sh` copies instead.
Until then, run `./install.sh` again after each edit, or the change never reaches `~/.claude/` ([Symlinks on Windows](#symlinks-on-windows)).

## Platform support

`bash` and `git` are the only requirements for installing the config.
Committing to this repo also wants `pre-commit`, which runs the [gates](docs/security.md#the-commit-gates) — `install.sh` says so and carries on without it, so a machine that only consumes the config needs nothing extra.
There is nothing here that ties the repo to one operating system:

- **macOS and Linux** work as-is, and get real symlinks by default — no Developer Mode step, so the [working loop](#the-working-loop) above is the live-edit one rather than the re-run-`install.sh` one.
- **Windows** works through Git Bash. `.gitattributes` normalizes line endings to LF so the scripts stay executable everywhere. Symlinks need Developer Mode, which is off on a new machine, so that is a step to do before the first install — [Symlinks on Windows](#symlinks-on-windows).

The Windows-specific pieces are inert elsewhere rather than broken: the `PowerShell(...)` entries in `permissions.ask` name a tool that does not exist on macOS, `md2pdf.sh` guards its `cygpath` calls behind `command -v`, and its browser search list already includes the `/Applications/` paths alongside the `C:\Program Files\` ones.

Where the sections below say "this Windows machine", they are reporting where the config happens to run today, not stating a requirement.
Developer Mode is the exception: it is off on every new Windows machine, so anyone installing on Windows meets it, not just me.

## Install on a new machine

Read this paragraph before running anything.
`install.sh` writes into `~/.claude/`, and it replaces `settings.json` rather than merging with one you already have.
If that directory has a history, [`install.sh` replaces `settings.json` wholesale](#installsh-replaces-settingsjson-wholesale) is the section to read first — every `permissions.allow` rule you have built up answering "Yes, and don't ask again" lives in that file.

**On Windows, turn on Developer Mode before the first run.**
Settings → For developers → Developer Mode on — under System on Windows 11, under Update & Security on Windows 10 — then restart Git Bash.
Windows will not let an ordinary user create a symlink without it, and every new machine arrives with it off, so `install.sh` reports the refusal and copies instead.
Copies work, but each edit here then needs another `./install.sh` to reach `~/.claude/`, and a file edited under `~/.claude` can be overwritten on the next run ([copies drift both ways](#copies-drift-both-ways)).
Turning it on takes an administrator; running the install from an elevated shell does the same job for one run.

See what it would do first. `--dry-run` changes nothing:

```bash
git clone https://github.com/francisco-camargo/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./install.sh --dry-run
```

It prints every move it would make. When that reads the way you want, drop the flag:

```bash
./install.sh
```

Then restart Claude Code, or open `/hooks` once, so it reloads settings.

`git` and `bash` are the whole requirement for this much.
`install.sh` symlinks `claude/settings.json`, `claude/CLAUDE.md`, and `claude/skills/md-to-pdf` into `~/.claude/`.
Anything already there is moved into `~/.claude/backups/` first — nothing is silently overwritten.
Use `--copy` to force copies instead of links.

### Making it your own

This repo is meant as a starting point rather than something to depend on.
Fork it, or clone it and point `origin` at your own remote, and everything from that commit on is yours to change.

Install `pre-commit` before running `install.sh`, and the same run also wires [the gates](docs/security.md#the-commit-gates) into your clone:

```bash
uv tool install pre-commit
```

`uv` is what I use; `pipx install pre-commit` or a `pip --user` install do the same job, and nothing here depends on which.
Either order works — `install.sh` says so when the gates end up off, and `pre-commit install` from inside the clone turns them on afterwards.

The gates are worth more in your copy than in mine.
A dotfiles repo grows toward shell profiles and git config, and that is where a credential eventually lands: see [how a secret would actually get out](docs/security.md#how-a-secret-would-actually-get-out).
Mine is small enough that there is nothing to catch yet, which is exactly the wrong moment to find out the gates were never on.

### `install.sh` replaces `settings.json` wholesale

`install.sh` treats every item the same way: back up what is there, then put the repo's version in its place.
That is right for `CLAUDE.md` and the skill, which are whole files this repo owns.
It is wrong for `settings.json`, because there is only one user settings file and everything user-level has to share it.

Claude Code reads settings in this order, highest first: managed, command line, `.claude/settings.local.json`, `.claude/settings.json`, `~/.claude/settings.json`.
The `settings.local.json` layer is per project, not per user, and there is no include or extends mechanism.
So an existing `~/.claude/settings.json` is not merged with this repo's — it is moved into `~/.claude/backups/` and replaced.

What that costs someone who already had one: their model choice, their `statusLine`, their `env` block, their MCP servers, and every `permissions.allow` rule they built up answering "Yes, and don't ask again".
Nothing is destroyed, but getting it back means merging two JSON files by hand, and the symptom is Claude Code asking again about commands it had stopped asking about a year ago.

This costs nothing on a machine already running this repo's settings, which is why it went unnoticed.
It is a real hazard for anyone else, and for a future machine of mine that has a history before the first `./install.sh`.
Until [Ask before replacing a file](TODO.md#ask-before-replacing-a-file) lands, copy `~/.claude/settings.json` somewhere safe first, then merge the pieces back by hand afterwards.

### Symlinks on Windows

Creating a symlink on Windows is a privilege ordinary users do not hold, and Developer Mode — which grants it — is off on a machine out of the box.
So copying is what Windows does by default, on any new machine rather than on this one in particular, until someone turns Developer Mode on or runs the install elevated.
Without the privilege the script notices, says so, and copies instead.

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
`git status` reports nothing, so the change looks like it was never made, and the next `./install.sh` replaces it with the repo's older copy.
The overwritten directory does get moved into `~/.claude/backups/`, so the work is recoverable, but only if you notice in time to go looking for it.

This has already happened once.
An `h4` rule added to `print.css` lived only in `~/.claude`, while the repo picked up two commits the live copy never saw.
Both sides had edits the other did not.

Until it is fixed, the rule is: edit files in this repo, never in `~/.claude`, then re-run `./install.sh`.
And before running the installer, diff the two trees so an in-place edit does not get thrown away:

```bash
diff -r claude/skills/md-to-pdf ~/.claude/skills/md-to-pdf
```

**To deal with next.** Both halves are tracked under [Open items](TODO.md#open-items): turning on Developer Mode, which ends the copying, and [asking before replacing a file](TODO.md#ask-before-replacing-a-file), which covers machines where Developer Mode is not on offer.
A copy-mode install should not be able to silently destroy work, and right now it can.

### A backup can load as a skill

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
| `claude/settings.json` | `~/.claude/settings.json` | Model choice, and the [hooks](#hooks) below |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | [Standing instructions](#standing-instructions) for every session, everywhere |
| `claude/skills/md-to-pdf/` | `~/.claude/skills/md-to-pdf/` | A [skill](#skills) that renders a Markdown file to a print-ready PDF |

## Hooks

Each gate below is an entry in `hooks.PreToolUse` in `claude/settings.json`.
A `PreToolUse` hook runs before every Bash and PowerShell tool call and can let it through, force an approval prompt, or refuse it outright.
The git gate backs its hook with further layers of permission rules; the rest are the hook alone.

Two rules hold for every gate here, and both are worth keeping if one is ever edited.

**`sed` and `grep` only** — no `jq`, `node`, or `python`, none of which are reliably installed.
Keep it that way, or a hook will silently stop firing on a machine that lacks the dependency.

**Test the pattern after JSON escaping, not before.**
Each pattern is a string inside `settings.json`, so an alternation written `\|\|` at a shell prompt has to survive as `\\|\\|`, and `\.` as `\\.`.
Get that wrong and the pattern still parses, still exits 0, and matches nothing.
Test the string pulled back out of `settings.json`, not the one typed into the shell.

To drop any one gate, delete its entry in `hooks.PreToolUse`.
To turn a refusal into a prompt, change that entry's `"permissionDecision": "deny"` to `"ask"`.

### The git approval gate

This gate requires explicit approval before Claude runs `git commit` or `git push`.
Three layers, because the first two have gaps:

1. **`hooks.PreToolUse`** — a sed+grep command that reads the command out of the tool payload and forces an approval prompt when it matches `git[^;&|]{0,60}(commit|push)`. This is the layer that matters: it catches compound commands like `cd /repo && git commit`, which the prefix-matching permission rules below miss entirely.
2. **`permissions.ask`** — rules for `Bash(git commit:*)`, `Bash(git push:*)` and the PowerShell equivalents. `ask` rules beat `allow` rules, so a project cannot grant itself permission later.
3. **`autoMode.soft_deny`** — stops auto mode's classifier from self-approving a commit, and spells out that "save this" or "version this" is not authorization.

To tighten it from "prompt me" to "never, I'll run git myself", move the entries from `permissions.ask` to `permissions.deny`.

### The sed gate

This gate denies `sed` edits outright.
Unlike the git gate it does not prompt, because there is no case where the answer is yes.

sed rewrites a file by regex, and code is full of characters a regex reads as syntax — `.`, `*`, `[`, `$`, `/`.
A pattern that looks literal matches more than it says.
`s/old/new/g` then replaces every match on every line rather than the one that was meant, `-i` writes the result straight over the file, and the command exits 0 either way.
Run by hand that is survivable, because you read the diff before moving on.
Run as one step in a longer task it is not: the mangled line becomes the base for the next several edits, and by the time it surfaces the diff is hard to untangle.

The hook denies a sed invocation carrying `-i`, `--in-place`, or an `s///` substitution.
It leaves `sed -n '1,50p' file` alone, so paging a file still works — and so does the git gate above, which is itself a `sed -n 's///p'` pipeline.
The refusal names the alternatives, so the response is to use the `Edit` tool or write a short script, not to look for a way around the hook.

One detail took a try to get right, and is worth keeping if this is ever edited.

**It trims the payload before matching.**
The hook reads the command out of the tool payload with the same `sed -n 's/.*"command"...//p'` extraction as the git gate.
That extraction is greedy in one direction only: it strips everything before the command but leaves the rest of the JSON — including the `description` field — on the line.
Any description containing `files,` or `functions,` then reads as an `s,` substitution and blocks an innocent command.
The second `sed 's/"[,}].*$//'` cuts the line at the end of the command value, which is what stops it.

### The uv gate

This gate denies a bare `python`, `pythonw`, or `py`, and any version suffix on the first of those — `python3`, `python3.12`.
Like the sed gate it refuses outright, with no prompt, because the answer never changes: run it through `uv`.

The reason is not taste.
On this machine `python` and `python3` on `PATH` are symlinks to `AppInstallerPythonRedirector.exe` — the Microsoft Store redirector, which opens a Store page and runs nothing.
There is no Python installed outside uv; the only real interpreter is the one under `%APPDATA%\uv\python\`.
So `python script.py` cannot succeed here, and the cost of trying is a wasted turn spent reading a failure that looks like a missing file rather than a missing interpreter.

The hook matches those names in command position — at the start, or after `;`, `&&`, `||`, `|`, or `(`.
That anchoring is what makes it worth a hook rather than a permission rule, for the same reason the git gate needs one: it catches `cd src && python app.py`, which prefix matching misses.

It deliberately leaves alone anything under `uv run`, including `uv run python -c ...`, where `python` is an argument rather than the command.
It also leaves an explicit interpreter path such as `.venv/Scripts/python.exe` alone, which is a deliberate choice, not the habit being corrected, and `python` used as an argument or inside a filename — `which python`, `grep -r python src/`, `cat python_notes.md`.
`pytest` is untouched too, despite sharing its first two letters with the `py` launcher.

The refusal names the `uv` forms to use, so the correction arrives in the same turn and the next attempt is `uv run`, not a hunt for the interpreter.

This is the gate that argued for the escaping rule at the top of this section: the alternation `\|\|` and the escaped `\.` both had to be written into JSON doubled.

`pip` is not covered.
`pip install` reaches for the same missing interpreter, and `uv pip` or `uv add` is the replacement — the omission is scope, not a finding that it is safe.

## Skills

A skill pairs a script with the description that tells Claude when to reach for it.

### The md-to-pdf skill

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
Two copies of one skill is a problem to fix by deleting one, not by keeping them both.

## Standing instructions

`~/.claude/CLAUDE.md` holds standing instructions Claude reads at the start of every session in every project — the home for preferences that otherwise get re-explained, and then re-explained again.
It is now in the repo as `claude/CLAUDE.md` and installed like everything else.
The entries so far arrived two ways: some had to be said once already and would otherwise have to be said again, and some are standards set up front.

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
>
> In the Bash tool, use heredocs (`<<'EOF'`) and POSIX quoting.
> The PowerShell here-string `@'...'@` is not Bash syntax and does not fail — Bash passes the `@` through as an ordinary character, silently embedding it in the text.
>
> In the PowerShell tool the reverse holds, and `&&` and `||` are parse errors in Windows PowerShell 5.1.

The general shape is worth noticing: anything corrected twice in two different sessions is a candidate.
A correction that only lives in one conversation is gone when that conversation ends.

### The preference that makes the same case

The wrapping convention is not a bug, which is the point — the file is for anything that would otherwise be re-explained, and preferences qualify.
Prose here was hard-wrapped to eighty columns, which splits sentences across lines and makes a one-word edit reflow every line after it: the diff reports a paragraph changed when a word did.
The convention that fixes it is one sentence per line, breaking at sentence boundaries only.
Markdown joins the lines back into a paragraph when rendered, so the output is identical and only the diffs improve.

Left in a conversation, that preference lasts until the conversation ends and the next session goes back to wrapping at eighty.
Written down here, it holds in every repo, including ones that have never heard of it.

This README was written in the old style and converted in one pass, which is what the rule asks for: a whole-file change of its own rather than a paragraph quietly reflowed while editing something else.

### The entry chosen rather than corrected

Orwell's six rules from *Politics and the English Language* are in there too.
Where the wrapping rule governs the line breaks, these govern the words: cut what can be cut, prefer the short word, prefer the active, and skip the jargon when a plain word carries the same meaning.
His sixth rule keeps the other five honest — break any of them sooner than say something clumsy — which matters, because a style rule applied past the point of sense costs more than it saves.

That entry arrived differently from the ones above.
Nothing went wrong first: no mangled commit, no paragraph reflowed for one word.
It is a standard set up front, which is the other legitimate way in.
The bar is not only "this has gone wrong twice" — it is also "this is general and durable enough to be worth saying before it costs anything."
What stays out is the preference that applies to one file, or the rule that would read as a surprise six months from now.

### Instructions are not enforcement

Worth being honest about the ceiling.
`CLAUDE.md` is advice the model reads, not a rule the machine applies — it lowers the odds, it does not remove them.
The `PreToolUse` hook that already gates commits could genuinely enforce this one: match `@'` in a Bash tool command and refuse it, the same way the gate stops an unapproved commit.
If the written instruction proves not to be enough, that is the escalation rather than wording it more emphatically.

### One caveat on contents

A global `CLAUDE.md` gets committed and pushed like everything else here, so [Security](docs/security.md) applies to it in full.
It is also a natural place to drift into recording machine specifics — absolute paths, host names, which drive holds what.
Keep it to preferences and conventions, and it stays portable to the next machine.

### What belongs here, and what belongs in a skill

Everything in this file is read at the start of every session in every project, whether or not that session touches the subject.
While it stays short that costs nothing.
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
The test is the same each time, and [Split standing instructions between CLAUDE.md and skills](TODO.md#split-standing-instructions-between-claudemd-and-skills) records what is left to decide.

## Security

[docs/security.md](docs/security.md) covers what this repo keeps out of git, the gates that stop a secret before it is committed, and what GitHub checks on push.

## Open items

Work that is started and unfinished is in [TODO.md](TODO.md#open-items).

## What else could live here

Nothing below is set up yet.
This is the list of things worth pulling in as the need comes up, roughly in order of how much repetition each one removes.

### More Claude Code configuration

- **More skills** — anything done twice by hand is a candidate. Skills carry the *when* and *why* alongside the script, which is what makes them worth more than a loose shell script.
- **`~/.claude/agents/`** — subagent definitions, if a specialized reviewer or researcher proves worth the setup.
- **`~/.claude/commands/`** — custom slash commands for repeated multi-step workflows.
- **`~/.claude/keybindings.json`** — key bindings, which is the file nobody rebuilds from memory on a new machine.
- **More hooks** — the same `PreToolUse` mechanism as the gates above can auto-format after edits, block writes to protected paths, or log what ran.

### Shared repo scaffolding

The files every repo starts with live in [repo-template](https://github.com/francisco-camargo/repo-template), because they concern every project and not one person's machines.

### Global git config

`~/.gitconfig` on this machine carries an editor, a name, and an address.
`init.defaultBranch`, `pull.rebase`, aliases, `core.excludesFile` — all of it is re-derived per machine or lived without, which is the drift this repo exists to end.

Git also solves here what `settings.json` could not, because a gitconfig can include another one:

```ini
[include]
    path = ~/git/dotfiles/git/gitconfig
```

The install appends a line instead of replacing a file someone already owns, so [asking before replacing a file](TODO.md#ask-before-replacing-a-file) has nothing to ask about there.
Two more things fall out of the same mechanism.
`includeIf "gitdir:~/git/work/"` gives one set of repos its own address without a `hosts/` directory ([per-machine differences](#per-machine-differences)).
And `core.excludesFile` pointing here is what retires the `.gitignore` copied into every repo, above.

Read [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) before the first commit of one: a credential helper and a remote URL with a token in it both live in this file.

### Machine setup

- **A bootstrap list** of what a machine needs, argued under [Install what this config already assumes](TODO.md#install-what-this-config-already-assumes) — it starts with the tools this repo's own config depends on.
- **Editor settings** — VS Code, covered on its own in [VS Code settings](#vs-code-settings) below.
- **Shell profile** — `.bashrc` for Git Bash, or the PowerShell profile, holding aliases and PATH tweaks. There is no `.bashrc` on this machine at all, and one line earns the file on its own: `export MSYS=winsymlinks:nativestrict` makes every `ln -s` in Git Bash behave the way `install.sh` has to force by hand ([Symlinks on Windows](#symlinks-on-windows)).

### VS Code settings

This is the next thing to pull in, so it gets more than a bullet.

The files worth versioning all live in one directory — `%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux:

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

One argument cuts the other way, and it is the new-machine one.
Redoing `settings.json` by hand takes a minute; rebuilding the extension set takes an afternoon, and what is missing from it only shows up when something stops working.
`code --list-extensions > vscode/extensions.txt` costs nothing to keep current, and it cannot drift the way `settings.json` does, because no UI writes back to it.
So take the extensions list first if the next machine is nearer than the next settings change.

Then pick a single source of truth, and let it be the repo.
This matters more for VS Code than it did for Claude Code, because `install.sh` is [copying rather than linking on this machine](#symlinks-on-windows), and VS Code has a settings UI that writes to `%APPDATA%` directly.
Editing settings through that UI while the repo holds the canonical copy produces two files that disagree, and the next `./install.sh` replaces the newer one with the repo's version.
The UI-edited file is not lost — `backup()` moves it into `backups/` first — but recovering a change from a backup in `%APPDATA%` is not a workflow anyone wants twice.
So: edit `vscode/settings.json` in the repo, commit, re-run `./install.sh`.
If a setting gets changed through the UI by reflex — and it will — copy it back into the repo before the next install, not after.

Enabling Developer Mode and getting real symlinks removes the whole problem, and is the single change that makes versioning editor settings pleasant instead of fiddly.
Worth doing first if you have the option.

Two things to expect.
VS Code settings collect absolute paths — `python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts that exist on one machine — and those are exactly what [Per-machine differences](#per-machine-differences) is about; strip or generalize them on the way in rather than committing a file that only works here.
And some extensions store tokens in `settings.json`, so read [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) before the first commit, not after.

### Per-machine differences

The moment a second machine has a genuinely different setting, the single-file approach strains.
The usual fix is a `hosts/<machine-name>/` directory that `install.sh` layers on top of the shared files after placing them, so shared config stays shared and only the differences are duplicated.
Worth doing when the need actually appears, not before.


### Before adding any of this

Shell profiles, git config, and bootstrap scripts are where credentials actually creep in — a remote URL with a token in it, an exported key in `.bashrc`.
Re-read [Security](docs/security.md) before pulling any of them in.
