# Plan: global git config

## Goal

Keep the git settings worth sharing in this repo, included from `~/.gitconfig`, so git behaves the same on every machine.

## Why

`~/.gitconfig` on this machine carries an editor, a name, and an address.
`init.defaultBranch`, `pull.rebase`, aliases, `core.excludesFile`: all of it is re-derived per machine or lived without, which is the drift this repo exists to end.

## Include rather than replace

A gitconfig can include another one, which `settings.json` could not:

```ini
[include]
    path = ~/git/dotfiles/git/gitconfig
```

The install appends a line instead of replacing a file someone already owns, so the installer has nothing to ask about.
Two more things fall out of the same mechanism.
`includeIf "gitdir:~/git/work/"` gives one set of repos its own address without a `hosts/` directory ([per-machine differences](../TODO.md#ideas)).
And `core.excludesFile` pointing here is what retires the `.gitignore` copied into every repo.

## Identity and credentials

- `user.email` should be GitHub's noreply address, which keeps the real one out of every commit.
- No `credential.helper store`: it writes the token to `~/.git-credentials` in plain text. SSH keys, or the Git Credential Manager that Git for Windows sets up, keep the secret out of any file this repo could pick up.

Read [Commit the reference, not the secret](../docs/security.md#commit-the-reference-not-the-secret) before the first commit: a credential helper and a remote URL with a token in it both live in this file.

## Steps

- [ ] Write `git/gitconfig` with the settings worth sharing: `init.defaultBranch`, `pull.rebase`, the noreply `user.email`, and any aliases in use.
- [ ] Have `install.sh` add the `[include]` to `~/.gitconfig` when it is missing, and report it under `--dry-run`.
- [ ] Add a global excludes file for OS clutter, and point `core.excludesFile` at it.

## Docs to update

- [ ] `README.md`: the new files, in the file table.
- [ ] [docs/install.md](../docs/install.md#what-the-installer-does): the include line the installer adds.
- [ ] repo-template's `TODO.md`: its idea to move OS clutter into the global excludes file waits on that file.
- [ ] francisco-camargo's git notes: replace the git credentials part with a link here.

## Updates to send

None.

## Open questions

- **A work address:** whether any repos need `includeIf` for a second identity yet.

## Done when

On a machine after `./install.sh`, `git config --show-origin init.defaultBranch` names the file in this repo.
