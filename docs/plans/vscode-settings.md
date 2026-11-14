# Plan: VS Code settings

The files worth versioning all live in one directory (`%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux):

- `settings.json`, the bulk of it
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

## The recommendation

Start with `settings.json` alone.
Add keybindings once there are any worth keeping, and the extensions list once a second machine exists to replay it onto; that file is the one that pays off only on a fresh install.

One argument cuts the other way, and it is the new-machine one.
Redoing `settings.json` by hand takes a minute; rebuilding the extension set takes an afternoon, and what is missing from it only shows up when something stops working.
`code --list-extensions > vscode/extensions.txt` costs nothing to keep current, and it cannot drift the way `settings.json` does, because no UI writes back to it.
So take the extensions list first if the next machine is nearer than the next settings change.

Then pick a single source of truth, and let it be the repo.
This matters more for VS Code than it did for Claude Code, because `install.sh` is [copying rather than linking on this machine](../install.md#symlinks-on-windows), and VS Code has a settings UI that writes to `%APPDATA%` directly.
Editing settings through that UI while the repo holds the canonical copy produces two files that disagree, and the next `./install.sh` replaces the newer one with the repo's version.
The UI-edited file is not lost (`backup()` moves it into `backups/` first), but recovering a change from a backup in `%APPDATA%` is not a workflow anyone wants twice.
So: edit `vscode/settings.json` in the repo, commit, re-run `./install.sh`.
If a setting gets changed through the UI by reflex, and it will, copy it back into the repo before the next install, not after.

Enabling Developer Mode and getting real symlinks removes the whole problem, and is the single change that makes versioning editor settings pleasant instead of fiddly.
Worth doing first if you have the option.

Settings Sync is a rival source of truth.
If VS Code syncs settings through a GitHub account, Sync and a versioned `settings.json` overwrite each other.
Turn Sync off for settings when the repo takes over, or decide Sync is enough and drop this item.
Worth carrying over either way: the Dark+ theme, relative line numbers, and the Vim extension with its keybindings.

`install.sh` installs markdownlint's fallback rules as `~/.markdownlint.yaml`; carry the setting that points `markdownlint.configFile` at `${userHome}/.markdownlint.yaml`.
The extension uses a repo's own `.markdownlint.yaml` first, and falls back to `configFile` in a repo without one.
The path must exist on every machine, which `${userHome}` and the install make sure of; a path into one repo makes the extension fail in every other.
The `markdownlint.config` setting is deprecated.

Two things to expect.
VS Code settings collect absolute paths (`python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts that exist on one machine), and those are exactly what [Per-machine differences](../../TODO.md#ideas) is about; strip or generalize them on the way in rather than committing a file that only works here.
And some extensions store tokens in `settings.json`, so read [Commit the reference, not the secret](../security.md#commit-the-reference-not-the-secret) before the first commit, not after.
