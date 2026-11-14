# Plan: shell profile and WSL config

## Goal

Keep a shell profile for Git Bash that sets `MSYS` and starts ssh-agent, and the WSL settings that survive a restart, in this repo.

## Shell profile

`.bashrc` for Git Bash, or the PowerShell profile, holding aliases and PATH tweaks.
There is no `.bashrc` on this machine at all, and one line earns the file on its own: `export MSYS=winsymlinks:nativestrict` makes every `ln -s` in Git Bash behave the way `install.sh` has to force by hand ([Symlinks on Windows](../docs/install.md#symlinks-on-windows)).
GitHub's [ssh-agent auto-start block](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows) belongs there too, so a key loads once per session; the block goes in the repo, the key never does.

## WSL config

`/etc/wsl.conf` inside a distro and `.wslconfig` in the Windows home directory.
A hand-edited `/etc/resolv.conf` reverts because WSL regenerates it at startup; `generateResolvConf = false` under `[network]` in `wsl.conf` keeps the edit.

## Steps

- [ ] Write `shell/bashrc` with the `MSYS` export and the ssh-agent block, and have `install.sh` place it.
- [ ] Write `wsl/wsl.conf` with `generateResolvConf = false`, and the way it reaches `/etc/wsl.conf`.
- [ ] Add `.wslconfig`, if any setting there is worth keeping.

## Docs to update

- [ ] `README.md`: the new files, in the file table.
- [ ] [docs/install.md](../docs/install.md#symlinks-on-windows): the profile sets `MSYS`, so the manual step goes.
- [ ] francisco-camargo's notes: replace the ssh-agent block and the WSL fixes with links here.

## Updates to send

None.

## Open questions

- **Place or source:** place `~/.bashrc` from the repo, or append a line to an existing one that sources the repo's file, as the git config plan does with `[include]`. Leaning source, for the same reason.
- **PowerShell:** whether a PowerShell profile is worth keeping too.
- **Reaching `/etc`:** `wsl.conf` lives inside the distro and needs root, outside what `install.sh` can do from Git Bash. A step run inside the distro, or a copy by hand?

## Done when

A new Git Bash window has `MSYS` set and loads the SSH key after one passphrase prompt, and an edit to `/etc/resolv.conf` survives `wsl --shutdown`.
