# Plan: shell profile and WSL config

## Shell profile

`.bashrc` for Git Bash, or the PowerShell profile, holding aliases and PATH tweaks.
There is no `.bashrc` on this machine at all, and one line earns the file on its own: `export MSYS=winsymlinks:nativestrict` makes every `ln -s` in Git Bash behave the way `install.sh` has to force by hand ([Symlinks on Windows](../install.md#symlinks-on-windows)).
GitHub's [ssh-agent auto-start block](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-git-for-windows) belongs there too, so a key loads once per session; the block goes in the repo, the key never does.

## WSL config

`/etc/wsl.conf` inside a distro and `.wslconfig` in the Windows home directory.
A hand-edited `/etc/resolv.conf` reverts because WSL regenerates it at startup; `generateResolvConf = false` under `[network]` in `wsl.conf` keeps the edit.
