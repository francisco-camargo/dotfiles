# dotfiles

Configuration files kept in one place so every machine behaves the same.

## Motivation

This repo holds the configuration I want on every machine and in every project.
It covers Claude Code: its settings and [hooks](#hooks), the [instructions](#standing-instructions) it reads each session, and its [skills](#skills).
[What's here](#whats-here) lists each file and where it installs.
[Candidates for later](TODO.md#what-else-could-live-here) are git config, VS Code settings, a shell profile, and the files each repo repeats, such as `.gitignore` and `.gitattributes`.

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

Without a repo, such a config file:

1. **Has no history.** Six months after changing a setting, you cannot recall what you changed or why.
2. **Drifts between machines.** You notice only when something behaves differently on one of them.
3. **Is lost on reinstall.** A new machine means rebuilding it from memory.

### Symlinks

A dotfiles repo makes the repo the real location, and the home directory a set of links to it.
`~/.claude/settings.json` becomes a **symlink**, a file that points to another path, here `claude/settings.json` in this repo.
Editing either path edits the repo.
`install.sh` creates the links.

That brings git to config:

- **One copy.** Each file exists once, and that copy is the current one.
- **A history.** Each change is a commit, so `git log` shows why a setting is what it is, and `git revert` undoes it.
- **Reproducible machines.** `git clone` and `./install.sh` make a new machine behave like the others.
- **Documentation.** The sections below explain what each piece does.

### The working loop

Edit a file here, commit it, and `git pull` on the other machines.
With symlinks, the change takes effect at once.

The link works the other way too.
Claude Code edits `~/.claude/settings.json` itself when you change a `/config` option stored in user settings, such as the theme.
That shows up here as an uncommitted change to `claude/settings.json`, which can conflict on the next `git pull`.
Commit it if every machine should have it, or `git restore` it if not.

Windows refuses symlinks to an ordinary user until Developer Mode is on, so `install.sh` copies instead.
Until then, run `./install.sh` again after each edit, or the change never reaches `~/.claude/` ([Symlinks on Windows](#symlinks-on-windows)).

## Platform support

`bash` and `git` are the only requirements for installing the config.
Committing to this repo also needs `pre-commit`, which runs the [gates](docs/security.md#the-commit-gates).
`install.sh` says so and carries on without it, so a machine that only uses the config needs nothing more.
Nothing here ties the repo to one operating system:

- **macOS and Linux** work as they are and get real symlinks by default, with no Developer Mode step, so the [working loop](#the-working-loop) above is the live-edit one rather than the re-run-`install.sh` one.
- **Windows** works through Git Bash. `.gitattributes` normalizes line endings to LF so the scripts stay executable everywhere. Symlinks need Developer Mode, which is off on a new machine, so turn it on before the first install: see [Symlinks on Windows](#symlinks-on-windows).

The Windows-specific pieces do nothing elsewhere rather than break: the `PowerShell(...)` entries in `permissions.ask` name a tool that does not exist on macOS, `md2pdf.sh` guards its `cygpath` calls behind `command -v`, and its browser search list includes the `/Applications/` paths alongside the `C:\Program Files\` ones.

Where the sections below say "this Windows machine", they report where the config happens to run, not a requirement.
Developer Mode is the exception: it is off on every new Windows machine, so anyone installing on Windows meets it.

## Install on a new machine

`install.sh` writes into `~/.claude/`, `~/.markdownlint.yaml`, and `~/.cspell-words.txt`.
Where a file is already there and differs from this repo's, it shows you which and asks whether to keep it, replace it, or see the difference.
With no terminal to ask on, it keeps it.
If you already have a `~/.claude/settings.json`, read [`install.sh` and an existing `settings.json`](#installsh-and-an-existing-settingsjson) first.

### On Windows, turn on Developer Mode first

Open Settings → For developers and turn Developer Mode on (under System on Windows 11, under Update & Security on Windows 10), then restart Git Bash.
Windows will not let an ordinary user create a symlink without it, and every new machine arrives with it off, so `install.sh` reports the refusal and copies instead.
Copies work, but each edit here then needs another `./install.sh` to reach `~/.claude/`, and the next run asks about any file edited under `~/.claude` ([copies drift both ways](#copies-drift-both-ways)).
Turning it on takes an administrator; running the install from an elevated shell does the same for one run.

### Run the installer

See what it would do first.
`--dry-run` changes nothing:

```bash
git clone https://github.com/francisco-camargo/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./install.sh --dry-run
```

It prints every move it would make.
When that reads the way you want, drop the flag:

```bash
./install.sh
```

A running Claude Code session picks up the new settings; see [when settings changes take effect](#when-settings-changes-take-effect).

`git` and `bash` are all this much needs.
`install.sh` symlinks `claude/settings.json`, `claude/CLAUDE.md`, and each skill under `claude/skills/` into `~/.claude/`.
It also links this repo's `.markdownlint.yaml` to `~/.markdownlint.yaml`, the rules the markdownlint extension uses in a repo without its own.
And it links `vscode/cspell-words.txt` to `~/.cspell-words.txt`, the words the Code Spell Checker extension accepts in every repo.
VS Code reads neither file until its user settings point at them:

```jsonc
"markdownlint.configFile": "${userHome}/.markdownlint.yaml",
"cSpell.customDictionaries": {
    "personal": { "name": "personal", "path": "~/.cspell-words.txt", "addWords": true, "scope": "user" }
},
```

`install.sh` leaves alone a file that matches the repo's.
It keeps one that differs unless you choose to replace it, and moves a replaced file into `~/.claude/backups/`, printing the command to restore it.
Use `--copy` to force copies instead of links, and `--replace-existing` to replace files that differ without asking.

After changing `install.sh`, run `tests/install-test.sh`.
It installs into a scratch home, never yours, and checks that the installer keeps what it should and replaces only what it is told to.

### Making it your own

Treat this repo as a starting point, not something to depend on.
Fork it, or clone it and point `origin` at your own remote, and everything from that commit on is yours to change.

Install `pre-commit` before running `install.sh`, and the same run also sets up [the gates](docs/security.md#the-commit-gates) in your clone, and in every repo you clone or create afterwards:

```bash
uv tool install pre-commit
```

`uv` is what I use; `pipx install pre-commit` or a `pip --user` install do the same job, and nothing here depends on which.
Either order works: `install.sh` says so when the gates end up off, and `pre-commit install` from inside the clone turns them on afterwards.

`install.sh` makes every `git clone` and `git init` run the equivalent of `pre-commit install`, so nobody has to remember it on a new clone.
It does this through git's template folder.
`install.sh` writes a pre-commit hook into `~/.git-template` and points `init.templateDir` at it, so git copies the hook into each repo as it clones or creates it.
The hook runs the gates in that repo's own `.pre-commit-config.yaml`, and skips a repo that has none.
A repo already on disk picks the hook up from `git init` run inside it, which adds what is missing and overwrites nothing.
If `init.templateDir` already points somewhere else, `install.sh` leaves it alone and says so.

The gates are worth more in your copy than in mine.
A dotfiles repo grows toward shell profiles and git config, and that is where a credential tends to land: see [how a secret would actually get out](docs/security.md#how-a-secret-would-actually-get-out).
Mine holds nothing to catch yet, and that is the wrong moment to find out the gates were never on.

### `install.sh` and an existing `settings.json`

There is one user settings file, and everything user-level has to share it.
Claude Code reads settings in this order, highest first: managed, command line, `.claude/settings.local.json`, `.claude/settings.json`, `~/.claude/settings.json`.
The `settings.local.json` layer is per project, not per user, and there is no include or extends mechanism, so `install.sh` cannot merge this repo's settings with yours.

So you choose one file or the other.
Replacing yours sets aside your model choice, your `statusLine`, your `env` block, your MCP servers, and every `permissions.allow` rule you built up answering "Yes, and don't ask again".
Keeping yours means going without this repo's hooks; `install.sh` says so, and you can copy the `"hooks"` block from `claude/settings.json` into your file by hand.

### Symlinks on Windows

Creating a symlink on Windows is a privilege ordinary users do not hold, and Developer Mode, which grants it, is off on a new machine.
So Windows copies by default, on any new machine and not only this one, until someone turns Developer Mode on or runs the install elevated.
Without the privilege the script notices, says so, and copies instead.

Git Bash adds a second requirement that is easy to miss.
Its `ln -s` copies the file and exits 0 unless `MSYS=winsymlinks:nativestrict` is set, so it never tries a link and nothing reports a problem.
Turning Developer Mode on by itself would not have changed the outcome.
`install.sh` sets that variable on the `ln` call, which makes the OS refusal visible for the `-L` check to catch.
The variable means nothing to `ln` on macOS or Linux.

With Developer Mode off and the shell not elevated, a native symlink fails with "operation not permitted" and `install.sh` copies.
Copies work, but they do not track edits: after changing anything in this repo, run `./install.sh` again to push the change out.
Turn Developer Mode on and you get real symlinks, and edits reach `~/.claude/` on their own.

### Copies drift both ways

When `~/.claude/skills/md-to-pdf/` is a copied directory and not a link, editing a skill in place, which is what Claude does when asked to change a global skill, leaves this repo clean.
`git status` reports nothing, so the change looks like it was never made.
This lost work once: an `h4` rule added to `print.css` lived only in `~/.claude`, while the repo picked up two commits the live copy never saw.

The next `./install.sh` sees that the copy differs and asks before replacing it; pick diff to see the edit, and carry it into the repo before replacing.
Better still, edit files in this repo, never in `~/.claude`, and turn on Developer Mode so there are no copies to drift.

### A backup can load as a skill

`install.sh` used to leave backups beside the original, as `<name>.bak.<timestamp>`.
That is harmless for a file and wrong for a skill.
Claude Code loads every directory under `~/.claude/skills/` as a skill, so `md-to-pdf.bak.20260904-012854` was a second copy of the skill, offered to the model beside the real one with an older description of when to use it.
Every reinstall added one more.

Backups collect in `~/.claude/backups/`, which nothing loads.
The general point holds for anything else installed here: `~/.claude` is not a plain directory, and where a file sits decides whether it runs.

### When settings changes take effect

Claude Code watches its settings files and applies most edits to a running session without a restart, hooks and permission rules included.
The reload is not instant: in testing, the tool call straight after an edit to a hook still ran the old version, and the next call ran the new one.
A few keys wait for the next session; of the ones this repo sets, that is `model`, which `/model` changes mid-session.

To confirm the gate works, ask Claude to make a trivial commit.
You should get an approval prompt.
If the commit goes through, run `/status` and check that its `Setting sources` line lists your user settings.

## What's here

| Path | Goes to | What it is |
| --- | --- | --- |
| `claude/settings.json` | `~/.claude/settings.json` | Model choice, and the [hooks](#hooks) below |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | [Standing instructions](#standing-instructions) for every session, everywhere |
| `claude/skills/md-to-pdf/` | `~/.claude/skills/md-to-pdf/` | A [skill](#skills) that renders a Markdown file to a print-ready PDF |
| `claude/skills/repo-template-check/` | `~/.claude/skills/repo-template-check/` | A [skill](#skills) that checks a repo against repo-template |
| `claude/skills/memory-audit/` | `~/.claude/skills/memory-audit/` | A [skill](#skills) that moves Claude's per-project memories into visible files |

## Hooks

Each gate below is an entry in `hooks.PreToolUse` in `claude/settings.json`.
A `PreToolUse` hook runs before a Bash or PowerShell tool call and can let it through, force an approval prompt, or refuse it.
The git gate backs its hook with further layers of permission rules; the rest are the hook alone.

To drop a gate, delete its entry in `hooks.PreToolUse`.
To turn a refusal into a prompt, change that entry's `"permissionDecision": "deny"` to `"ask"`.

### Rules for every gate

Keep these when you edit a gate.

#### `sed` and `grep` only

Use no `jq`, `node`, or `python`, none of which are reliably installed.
Keep it that way, or a hook will silently stop firing on a machine that lacks the dependency.

#### Test the pattern after JSON escaping

Each pattern is a string inside `settings.json`, so an alternation written `\|\|` at a shell prompt has to survive as `\\|\\|`, and `\.` as `\\.`.
Get that wrong and the pattern still parses, still exits 0, and matches nothing.
Test the string pulled back out of `settings.json`, not the one typed into the shell.

Claude Code then turns each `\\` into `\` once more before the shell runs the hook, so a doubled backslash in the decoded string reaches `grep` single.
To match a literal backslash, write `[\\]` in the JSON: `grep` reads a backslash inside brackets as itself, and no layer changes it.

#### A command can start on a later line

The hooks read the raw JSON payload, where a newline in a multi-line command arrives as the two characters `\n`.
A gate that anchors a command to the start or to `;`, `&&`, `|` must also accept `\n` before it, or the second line of a call slips through.

#### A gate runs only when its command does

The `sed` and uv gates carry an `if` rule, `Bash(sed *)` or `Bash(py*)`, so Claude Code starts them only when some part of the call runs `sed` or a name starting with `py`.
Claude Code splits the call itself, so `sed -i` inside quotes, a commit message, or a heredoc does not start the gate.
An `if` rule names one tool, so each gate has a Bash handler and a PowerShell handler with the same command; `tests/hooks-test.sh` fails if the copies differ.

#### Text after `git commit` belongs to the git gate

The `sed` and uv gates cut the command at `git … commit` before matching, so a commit message that mentions `sed -i` or starts a line with `python` goes through even when a real `sed` elsewhere in the call starts the gate.
The git gate already shows the whole command for approval.

#### Run the test after a change

`tests/hooks-test.sh` runs each gate as written in `settings.json` against sample commands; run it after changing one.

### The git approval gate

This gate requires your approval before Claude runs `git commit` or `git push`.
It has three layers, because the first two have gaps:

1. **`hooks.PreToolUse`**: a sed+grep command that reads the command out of the tool payload and forces an approval prompt when it matches `git[^;&|]{0,60}(commit|push)`. It catches forms the permission rules below miss: an option before the subcommand, as in `git -C /repo commit`, and git run inside another shell, as in `bash -c 'git commit'`.
2. **`permissions.ask`**: rules for `Bash(git commit:*)`, `Bash(git push:*)` and the PowerShell equivalents. Claude Code checks them against each part of a chained command, so they catch `cd /repo && git commit`. `ask` rules beat `allow` rules, so a project cannot grant itself permission later.
3. **`autoMode.soft_deny`**: stops auto mode's classifier from approving a commit itself, and spells out that "save this" or "version this" is not authorization.

To tighten it from "prompt me" to "never, I'll run git myself", move the entries from `permissions.ask` to `permissions.deny`.

### The sed gate

This gate denies `sed` edits outright.
Unlike the git gate it does not prompt, because the answer is never yes.

sed rewrites a file by regex, and code is full of characters a regex reads as syntax: `.`, `*`, `[`, `$`, `/`.
A pattern that looks literal matches more than it says.
`s/old/new/g` then replaces every match on every line rather than the one that was meant, `-i` writes the result straight over the file, and the command exits 0 either way.
Run by hand that is survivable, because you read the diff before moving on.
Run as one step in a longer task it is not: the mangled line becomes the base for the next several edits, and by the time it surfaces the diff is hard to untangle.

The hook denies a sed invocation carrying `-i`, `--in-place`, or an `s///` substitution.
It leaves `sed -n '1,50p' file` alone, so paging a file still works, and so does the git gate above, which is itself a `sed -n 's///p'` pipeline.
The refusal names the alternatives, so the response is to use the `Edit` tool or write a short script, not to look for a way around the hook.

#### It trims the payload before matching

This step took a second try to get right; keep it if you edit the gate.

The hook reads the command out of the tool payload with the same `sed -n 's/.*"command"...//p'` extraction as the git gate.
That extraction is greedy in one direction only: it strips everything before the command but leaves the rest of the JSON, including the `description` field, on the line.
Any description containing `files,` or `functions,` then reads as an `s,` substitution and blocks a harmless command.
The second `sed 's/"[,}].*$//'` cuts the line at the end of the command value, which stops it.

### The uv gate

This gate denies a bare `python`, `pythonw`, or `py`, and the first of those with any version suffix, such as `python3` or `python3.12`.
Like the sed gate it refuses outright, with no prompt, because the answer never changes: run it through `uv`.

The reason is not taste.
On this machine `python` and `python3` on `PATH` are symlinks to `AppInstallerPythonRedirector.exe`, the Microsoft Store redirector, which opens a Store page and runs nothing.
No Python is installed outside uv; the only real interpreter is the one under `%APPDATA%\uv\python\`.
So `python script.py` cannot succeed here, and trying costs a turn spent reading a failure that looks like a missing file rather than a missing interpreter.

The hook matches those names in command position: at the start of a line, or after `;`, `&&`, `||`, `|`, or `(`.
A deny rule such as `Bash(python *)` would also catch `cd src && python app.py`, since Claude Code checks each part of a chained command, but it refuses without saying what to run instead.
The hook's message is what makes it worth a hook.

It leaves alone anything under `uv run`, including `uv run python -c ...`, where `python` is an argument rather than the command.
It also leaves alone an explicit interpreter path such as `.venv/Scripts/python.exe`, which is a choice and not the habit being corrected, and `python` used as an argument or inside a filename: `which python`, `grep -r python src/`, `cat python_notes.md`.
`pytest` passes too, though it shares its first two letters with the `py` launcher.

The refusal names the `uv` forms to use, so the correction arrives in the same turn and the next attempt is `uv run`, not a hunt for the interpreter.

This gate prompted the rule to [test the pattern after JSON escaping](#test-the-pattern-after-json-escaping): the alternation `\|\|` and the escaped `\.` both had to be written into JSON doubled.

The gate does not cover `pip`.
`pip install` reaches for the same missing interpreter, and `uv pip` or `uv add` replaces it; leaving it out is a matter of scope, not a finding that it is safe.

## Skills

A skill pairs a script with the description that tells Claude when to use it.

### The md-to-pdf skill

```bash
~/.claude/skills/md-to-pdf/scripts/md2pdf.sh some-document.md
```

`md2pdf.sh` converts Markdown to HTML with a small awk script, inlines `assets/print.css`, and prints it with headless Chrome or Edge.
It needs no pandoc or node.
The stylesheet holds all the layout, including page breaks and repeated table headers.
See `claude/skills/md-to-pdf/SKILL.md` for details.

### The repo-template-check skill

Ask Claude to check a repo against [repo-template](https://github.com/francisco-camargo/repo-template), which holds the files every project starts with.

```bash
~/.claude/skills/repo-template-check/scripts/check.sh some-project
```

The script does what code can settle: which template files the project lacks, which match, and which template lines a differing copy lacks.
Claude does the rest: it offers the missing files, explains each gap, and suggests what to adopt, changing nothing until asked.
See `claude/skills/repo-template-check/SKILL.md` for details.

### The memory-audit skill

Ask Claude to audit a project's memories.
Claude Code keeps them outside every repo, where they shape sessions without anyone seeing them.

```bash
~/.claude/skills/memory-audit/scripts/find.sh some-project
```

The script finds the project's memory directory and prints every memory; `--all` covers every project.
Claude then proposes a visible home for each one, such as a `CLAUDE.md`, a hook, or the README, and waits for approval.
Once approved, it commits each move and deletes the memory after the commit lands.
See `claude/skills/memory-audit/SKILL.md` for details.

### Skill scope, and duplicates

A skill installed here lands in `~/.claude/skills/` and is available in every project.
A skill committed to a repo's own `.claude/skills/` is available only in that repo.
When the same skill name exists in both, the project copy wins.
Two copies of one skill is a problem to fix by deleting one, not by keeping both.

## Standing instructions

`~/.claude/CLAUDE.md` holds standing instructions Claude reads at the start of every session in every project: the home for preferences I would otherwise explain again and again.
The repo keeps it as `claude/CLAUDE.md`, and `install.sh` installs it like everything else.
The entries arrived two ways: some I had said once already and would otherwise say again, and some are standards set up front.

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

### The preference that makes the same case

The wrapping convention is not a bug, which is the point: the file is for anything I would otherwise explain again, and preferences qualify.
Prose here was hard-wrapped to eighty columns, which splits sentences across lines and makes a one-word edit reflow every line after it: the diff reports a paragraph changed when a word did.
The convention that fixes it is one sentence per line, breaking at sentence boundaries only.
Markdown joins the lines back into a paragraph when rendered, so the output is identical and only the diffs improve.

Left in a conversation, that preference lasts until the conversation ends, and the next session goes back to wrapping at eighty.
Written down here, it holds in every repo, including ones that have never heard of it.

I wrote this README in the old style and converted it in one pass, as the rule asks: a whole-file change of its own rather than a paragraph quietly reflowed while editing something else.

### The entry chosen rather than corrected

Orwell's six rules from *Politics and the English Language* are in there too.
Where the wrapping rule governs the line breaks, these govern the words: cut what can be cut, prefer the short word, prefer the active, and skip the jargon when a plain word carries the same meaning.
His sixth rule, to break any of them sooner than say anything barbarous, limits the other five, and that matters because a style rule applied past the point of sense costs more than it saves.

That entry arrived differently from the ones above.
Nothing went wrong first: no mangled commit, no paragraph reflowed for one word.
It is a standard set up front, which is the other fair way in.
The bar is not only "this has gone wrong twice"; it is also "this is general and lasting enough to say before it costs anything".
What stays out is the preference that applies to one file, or the rule that would surprise a reader six months from now.

### Instructions are not enforcement

This approach has a limit.
`CLAUDE.md` is advice the model reads, not a rule the machine applies: it lowers the odds and does not remove them.
The `PreToolUse` hook that gates commits could enforce this one: match `@'` in a Bash tool command and refuse it, the same way the gate stops an unapproved commit.
If the written instruction proves not enough, that is the next step, rather than wording it more forcefully.

### One caveat on contents

A global `CLAUDE.md` gets committed and pushed like everything else here, so [Security](docs/security.md) applies to it in full.
It also invites machine specifics: absolute paths, host names, which drive holds what.
Keep it to preferences and conventions, and it stays portable to the next machine.

### What belongs here, and what belongs in a skill

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
The test is the same each time, and [Split standing instructions between CLAUDE.md and skills](TODO.md#split-standing-instructions-between-claudemd-and-skills) records what is left to decide.

## Security

[docs/security.md](docs/security.md) covers what this repo keeps out of git, the gates that stop a secret before it is committed, and what GitHub checks on push.

## Open items

Work that is started and unfinished is in [TODO.md](TODO.md#open-items), along with [what else could live here](TODO.md#what-else-could-live-here).
