# Plan: VS Code settings

## Goal

Keep VS Code's `settings.json`, keybindings, and extensions list in this repo, with the repo as the one source of truth.

## Why

Redoing `settings.json` by hand takes a minute; rebuilding the extension set takes an afternoon, and what is missing from it only shows up when something stops working.

## The files

They all live in one directory (`%APPDATA%\Code\User\` on Windows, `~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux):

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
The extensions list is a script input rather than a symlink target, so it wants its own small `vscode/install-extensions.sh`.
It costs nothing to keep current, and it cannot drift the way `settings.json` does, because no UI writes back to it.

## One source of truth

VS Code has a settings UI that writes to `%APPDATA%` directly, and `install.sh` is [copying rather than linking on this machine](../install.md#symlinks-on-windows).
Editing settings through that UI while the repo holds the canonical copy produces two files that disagree, and the next `./install.sh` replaces the newer one with the repo's version.
The UI-edited file is not lost (`backup()` moves it into `backups/` first), but recovering a change from there is slow.
So: edit `vscode/settings.json` in the repo, commit, re-run `./install.sh`, and copy back any setting changed through the UI before the next install.
Developer Mode, and real symlinks, remove the problem.

Settings Sync is a rival source of truth.
If VS Code syncs settings through a GitHub account, Sync and a versioned `settings.json` overwrite each other.

## Keybindings

Settings Sync keeps one keybindings file per platform (`settingsSync.keybindingsPerPlatform`, on by default).
The repo keeps one `vscode/keybindings.json` for every platform instead, and `install.sh` places it everywhere.
A binding that differs by platform, such as `ctrl` on Windows and `cmd` on macOS, gets a `"when"` clause with `isMac` or `isWindows`, rather than a second file.

The Vim extension's bindings (`vim.normalModeKeyBindings` and the like) are settings, so they travel in `settings.json`, not here.

## What to carry over, and what to strip

- Carry the Dark+ theme, relative line numbers, and the Vim extension with its keybindings.
- Carry `markdownlint.configFile` set to `${userHome}/.markdownlint.yaml`, the fallback rules `install.sh` installs. The extension uses a repo's own `.markdownlint.yaml` first. A path into one repo would make the extension fail in every other. The `markdownlint.config` setting is deprecated.
- Strip absolute paths (`python.defaultInterpreterPath`, terminal profiles naming a specific shell, fonts that exist on one machine), which belong to [Per-machine differences](../../TODO.md#ideas).
- Strip tokens: some extensions store them in `settings.json`, so read [Commit the reference, not the secret](../security.md#commit-the-reference-not-the-secret) before the first commit.

## Steps

- [ ] Decide between Settings Sync and the repo, and turn Sync off for settings if the repo wins.
- [ ] Add `vscode/extensions.txt` and `vscode/install-extensions.sh`.
- [ ] Add `vscode/settings.json`, stripped of machine paths and tokens, and have `install.sh` place it.
- [ ] Add `vscode/keybindings.json`, once there are keybindings worth keeping, and have `install.sh` place it.

## Docs to update

- [ ] `README.md`: the new files, in the file table.
- [ ] [docs/install.md](../install.md): the VS Code destination and the extensions script.
- [ ] francisco-camargo's notes: replace the VS Code settings part with a link here.

## Updates to send

None.

## Open questions

- **Sync or the repo:** leaning the repo, since it versions and diffs; Sync is enough only if neither matters.
- **Order:** the extensions list first if the next machine is nearer than the next settings change, which is the order the steps take.

## Done when

On a second machine, `./install.sh` and `vscode/install-extensions.sh` give the same editor as this one.
