# Security

The repo is public: anyone can read every commit, past and present.
It also gets cloned to every machine, sits in plain text in every backup, and is readable by anything running as you.
Decide what goes in it on that basis.

## What is in here today

Nothing sensitive.
`settings.json` holds a model name and permission rules, `install.sh` holds paths, the skill is shell, awk, and CSS.
Searching the entire history — not just the current files — for key, token, and password patterns turns up only this README talking about them.
That is the state to preserve, and it is worth re-checking whenever the repo grows.

## The directory this installs into is full of secrets

This is the real hazard, and it is easy to miss.
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

## Commit the reference, not the secret

`settings.json` supports an `env` block, which is exactly where someone would paste an `ANTHROPIC_API_KEY` to make something work.
Don't.
Set the variable in the shell profile or the OS environment and let the config refer to it by name.
The same rule covers every future addition: API keys, tokens, `~/.ssh/` private keys, `.env` files, anything with a password in it.

Backups are covered by where they land, not by a rule.
`install.sh` moves whatever it replaced into `~/.claude/backups/`, outside this repo, so those copies of real local config are not somewhere git can pick them up.
`.gitignore` covers the other direction, naming the credential files that would cost something if one ever landed here.

## Git history does not forget

If a secret is ever committed, deleting it in a later commit does not remove it.
It stays in every clone, in every fork, and on GitHub's servers.
The fix, in order:

1. **Rotate the credential.** Assume it is burned. This is the step that actually matters.
2. Rewrite the history with `git filter-repo` and force-push, as cleanup. The "Protect main" ruleset blocks that push, so turn it off for the push and back on after.

## This repo runs code on every machine that installs it

`install.sh` is a script you execute.
More significantly, the `PreToolUse` hooks in `settings.json` run a shell command on *every* Bash and PowerShell tool call on every machine that has installed it.
Whatever lands in this repo, runs.

That makes write access to this repo equivalent to code execution on all your machines:

- Keep 2FA on the GitHub account.
- Read the diff before `git pull && ./install.sh` on another machine, the same way you would for any script handed to you.
- Treat a pull request against it as a change to a security-sensitive script, not a config tweak. A stranger's change still needs the owner to merge it.
- Keep the "Protect main" ruleset, which blocks force pushes to the default branch and its deletion, with no one allowed to bypass it. It does not require pull requests, which would put each of the owner's direct pushes through a bypass.

## A secret scanner, once it is worth the setup

A pre-commit hook running `gitleaks` or `trufflehog` blocks the accidental commit before it happens.
Overkill at the current size — there is nothing here to catch.
Worth adding once the repo grows to shell profiles and git config, which is where credentials genuinely creep in: a remote URL with a token embedded in it, an alias carrying a password, an exported key in `.bashrc`.

That "once" arrived, and the gates are in — see [the commit gates](#the-commit-gates).

## The commit gates

`.pre-commit-config.yaml` holds what runs before a commit is created, and `install.sh` writes the hook into the clone.

| Gate | What it stops |
| --- | --- |
| `gitleaks` | A recognized credential anywhere in the staged diff |
| `detect-private-key` | A private key pasted into a tracked file |
| `check-shebang-scripts-are-executable` | A script committed without its executable bit, which `core.filemode=false` makes easy to do on Windows and impossible to notice there |
| `check-added-large-files` | A stray blob, which is usually a dump or an archive |
| `check-merge-conflict` | Conflict markers committed by accident |
| `end-of-file-fixer`, `trailing-whitespace` | Whitespace that would otherwise show up in someone else's diff |
| `scripts/check-anchors.sh` | A Markdown link to a heading that is not there |

Both directions are tested rather than assumed: a planted AWS key pair is caught as `aws-access-token` and `generic-api-key`, and a broken anchor fails the commit.

The framework rather than the hand-written script this repo first planned, for two reasons.
`gitleaks` detects far more than any amount of `grep` I would write, and people who watch credential formats change maintain it.
And `.pre-commit-config.yaml` is an ordinary tracked file, so it clones; only the hook that calls it has to be written per clone, which is the one thing `install.sh` adds.

The anchor check is here because a heading rename leaves broken links behind and nothing reports them.
That is not a security gate, but it is the same shape of problem: a change that quietly invalidates something elsewhere in the repo.

The cost is paid once per machine rather than once per repo, and it is larger than it looks.
The first hook run builds roughly 340 MB of cached environments under `~/.cache/pre-commit`, most of it the Go toolchain `gitleaks` is built with.
`pre-commit clean` empties it.

`install.sh` does not install `pre-commit` itself, because placing config files should not drag a global Python tool onto a machine as a side effect.
It checks for the tool, and when it is missing it says so as the very last thing it prints.
That placement is the point: a gate nobody knows is off is exactly what this layer is otherwise blind to.

`--no-verify` still skips all of it, and none of it runs for someone who never ran `install.sh`.
That is the right trade when the thing being defended against is an accident rather than an attacker.

## How a secret would actually get out

Nobody is going to type a password into `settings.json`.
The realistic leak is this repo starting to track a file that already holds a credential.
Two places it could come from, and the repo is growing toward both.

**One: the auth token, which already sits in the directory this repo mirrors.**
`~/.claude/.credentials.json` holds it.
Nothing copies it today, because `install.sh` names every file it places ([The directory this installs into is full of secrets](#the-directory-this-installs-into-is-full-of-secrets)).
Swap that allowlist for a sweep of `~/.claude` and the token ships with the rest.

**Two: the config files queued up to arrive next.**
[What else could live here](../README.md#what-else-could-live-here) reaches for shell profiles, global git config, VS Code settings, and a bootstrap script.
Every one of those is a place a credential hides: a remote URL with a token in `.gitconfig`, a credential helper, an extension token in VS Code's own `settings.json`, an `export` in `.bashrc`.

[A secret scanner, once it is worth the setup](#a-secret-scanner-once-it-is-worth-the-setup) called a scanner overkill at this size, and said to revisit that once the repo grew into those files.
That is why [the commit gates](#the-commit-gates) run `gitleaks`.

## Four layers, and what each one misses

| Layer | Catches | Misses | Cost |
| --- | --- | --- | --- |
| GitHub push protection | Recognized credential formats, server side, blocks the push | Passwords, host names, anything without a known token shape | A checkbox |
| Hardened `.gitignore` | Whole files — `.credentials.json`, `.env`, private keys | `git add -f`, and secrets pasted inside tracked files | A list of filenames |
| A `pre-commit` hook | Secrets pasted into tracked files, which the two above miss | `--no-verify`, and anyone who never enabled it | A config file, and `pre-commit` on the machine |
| `gitleaks` in Actions | Whatever reached the remote anyway, `--no-verify` included | Runs after the push — on a public repo, after it is already published | A workflow file |

Push protection is on for this repo.
It and secret scanning are free on a public repository, and GitHub does not offer them on a private one owned by a personal account.
Both are off by default: an administrator turns them on under Settings → Advanced Security (formerly Code security), or from inside a clone:

```sh
gh api -X PATCH 'repos/{owner}/{repo}' \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
gh api 'repos/{owner}/{repo}' --jq .security_and_analysis
```

Push protection blocks the push and says why.
Anyone with write access can bypass it by giving a reason, which is the right trade when the thing being defended against is an accident rather than an attacker.

The Actions scan reports; it does not block.
By the time it fires, the commit is already public.
So this repo has no such workflow: `gitleaks` runs only in the local `pre-commit` hook, before a commit exists, and push protection guards the remote.

## Repo-local hooks, or global, and the trap in the global one

A `pre-commit` hook needs `core.hooksPath`, because `.git/hooks/` is not cloned.

- **Repo-local**, set by `install.sh` from inside this repo. Narrow and safe, and covers only this repo.
- **Global**, pointing at this repo from the global git config. This is the "solve it once, not once per repo" form the [Motivation](../README.md#motivation) section argues for.

The trap is that a global `core.hooksPath` overrides per-repo hooks everywhere.
Any repo shipping its own `pre-commit` stops running it, with nothing to say so.
Repo-local first, then; global is a separate decision that needs an answer to that objection before it is worth taking.

Settled, and the trap turned out to be avoidable.
Using [the framework](#the-commit-gates) means no `core.hooksPath` at all: `pre-commit install` writes an ordinary `.git/hooks/pre-commit` into this clone, so nothing is redirected and no other repo is touched.

The global form is still there when the appetite arrives, and it has no trap either.
`pre-commit init-templatedir` sets `init.templateDir`, so every repo cloned or created afterwards gets a real hook of its own rather than a redirect.
The catch is only that it reaches new clones, not the repos already sitting on the machine.
