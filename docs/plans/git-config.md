# Plan: global git config

`~/.gitconfig` on this machine carries an editor, a name, and an address.
`init.defaultBranch`, `pull.rebase`, aliases, `core.excludesFile`: all of it is re-derived per machine or lived without, which is the drift this repo exists to end.

Git also solves here what `settings.json` could not, because a gitconfig can include another one:

```ini
[include]
    path = ~/git/dotfiles/git/gitconfig
```

The install appends a line instead of replacing a file someone already owns, so the installer has nothing to ask about there.
Two more things fall out of the same mechanism.
`includeIf "gitdir:~/git/work/"` gives one set of repos its own address without a `hosts/` directory ([per-machine differences](../../TODO.md#per-machine-differences)).
And `core.excludesFile` pointing here is what retires the `.gitignore` copied into every repo.

Identity and credentials come with it.
`user.email` should be GitHub's noreply address, which keeps the real one out of every commit.
And no `credential.helper store`: it writes the token to `~/.git-credentials` in plain text.
SSH keys, or the Git Credential Manager that Git for Windows sets up, keep the secret out of any file this repo could pick up.

Read [Commit the reference, not the secret](../security.md#commit-the-reference-not-the-secret) before the first commit of one: a credential helper and a remote URL with a token in it both live in this file.
