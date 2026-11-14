# Install

The [README](../README.md#install-on-a-new-machine) has the commands; this page covers the rest.

## Platform support

`bash` and `git` are the only requirements for installing the config.
Committing to this repo also needs `pre-commit`, which runs the [gates](security.md#the-commit-gates).
`install.sh` says so and carries on without it, so a machine that only uses the config needs nothing more.
Nothing here ties the repo to one operating system:

- **macOS and Linux** work as they are and get real symlinks by default, with no Developer Mode step, so the [working loop](../README.md#the-working-loop) is the live-edit one rather than the re-run-`install.sh` one.
- **Windows** works through Git Bash. `.gitattributes` normalizes line endings to LF so the scripts stay executable everywhere. Symlinks need Developer Mode, which is off on a new machine, so turn it on before the first install: see [Symlinks on Windows](#symlinks-on-windows).

The Windows-specific pieces do nothing elsewhere rather than break: the `PowerShell(...)` entries in `permissions.ask` name a tool that does not exist on macOS, `md2pdf.sh` guards its `cygpath` calls behind `command -v`, and its browser search list includes the `/Applications/` paths alongside the `C:\Program Files\` ones.

Where the sections below say "this Windows machine", they report where the config happens to run, not a requirement.
Developer Mode is the exception: it is off on every new Windows machine, so anyone installing on Windows meets it.

## On Windows, turn on Developer Mode first

Open Settings → For developers and turn Developer Mode on (under System on Windows 11, under Update & Security on Windows 10), then restart Git Bash.
Windows will not let an ordinary user create a symlink without it, and every new machine arrives with it off, so `install.sh` reports the refusal and copies instead.
Copies work, but each edit here then needs another `./install.sh` to reach `~/.claude/`, and the next run asks about any file edited under `~/.claude` ([copies drift both ways](#copies-drift-both-ways)).
Turning it on takes an administrator; running the install from an elevated shell does the same for one run.

## What the installer does

`install.sh` writes into `~/.claude/`, `~/.markdownlint.yaml`, and `~/.cspell-words.txt`, and needs only `git` and `bash`.
Where a file is already there and differs from this repo's, it shows you which and asks whether to keep it, replace it, or see the difference.
With no terminal to ask on, it keeps it.
A running Claude Code session picks up the new settings; see [when settings changes take effect](#when-settings-changes-take-effect).

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

## Making it your own

Treat this repo as a starting point, not something to depend on.
Fork it, or clone it and point `origin` at your own remote, and everything from that commit on is yours to change.

Install `pre-commit` before running `install.sh`, and the same run also sets up [the gates](security.md#the-commit-gates) in your clone, and in every repo you clone or create afterwards:

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
A dotfiles repo grows toward shell profiles and git config, and that is where a credential tends to land: see [how a secret would get out](security.md#how-a-secret-would-get-out).
Mine holds nothing to catch yet, and that is the wrong moment to find out the gates were never on.

## `install.sh` and an existing `settings.json`

There is one user settings file, and everything user-level has to share it.
Claude Code reads settings in this order, highest first: managed, command line, `.claude/settings.local.json`, `.claude/settings.json`, `~/.claude/settings.json`.
The `settings.local.json` layer is per project, not per user, and there is no include or extends mechanism, so `install.sh` cannot merge this repo's settings with yours.

So you choose one file or the other.
Replacing yours sets aside your model choice, your `statusLine`, your `env` block, your MCP servers, and every `permissions.allow` rule you built up answering "Yes, and don't ask again".
Keeping yours means going without this repo's hooks; `install.sh` says so, and you can copy the `"hooks"` block from `claude/settings.json` into your file by hand.

## Symlinks on Windows

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

## Copies drift both ways

When `~/.claude/skills/md-to-pdf/` is a copied directory and not a link, editing a skill in place, which is what Claude does when asked to change a global skill, leaves this repo clean.
`git status` reports nothing, so the change looks like it was never made.
This lost work once: an `h4` rule added to `print.css` lived only in `~/.claude`, while the repo picked up two commits the live copy never saw.

The next `./install.sh` sees that the copy differs and asks before replacing it; pick diff to see the edit, and carry it into the repo before replacing.
Better still, edit files in this repo, never in `~/.claude`, and turn on Developer Mode so there are no copies to drift.

## A backup can load as a skill

`install.sh` used to leave backups beside the original, as `<name>.bak.<timestamp>`.
That is harmless for a file and wrong for a skill.
Claude Code loads every directory under `~/.claude/skills/` as a skill, so `md-to-pdf.bak.20260904-012854` was a second copy of the skill, offered to the model beside the real one with an older description of when to use it.
Every reinstall added one more.

Backups collect in `~/.claude/backups/`, which nothing loads.
The general point holds for anything else installed here: `~/.claude` is not a plain directory, and where a file sits decides whether it runs.

## When settings changes take effect

Claude Code watches its settings files and applies most edits to a running session without a restart, hooks and permission rules included.
The reload is not instant: in testing, the tool call straight after an edit to a hook still ran the old version, and the next call ran the new one.
A few keys wait for the next session; of the ones this repo sets, that is `model`, which `/model` changes mid-session.

To confirm the gate works, ask Claude to make a trivial commit.
You should get an approval prompt.
If the commit goes through, run `/status` and check that its `Setting sources` line lists your user settings.
