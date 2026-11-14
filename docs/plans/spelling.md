# Plan: settle how spelling gets checked

`cspell.json` sits in the repo root and the VS Code extension finds it without being told to, so a misspelling is underlined as I type it.
When a commit is created, `typos` checks it, from the pre-commit config this repo shares with [repo-template](https://github.com/francisco-camargo/repo-template/blob/main/template/.pre-commit-config.yaml).

The two tools work differently.
`typos` carries a list of known misspellings and flags only those, which keeps it quiet and spares it a word list.
`cspell` works from dictionaries and flags anything absent from them, which is stricter and is why the word list in `cspell.json` had to be written before it was usable here.

`cspell` costs a second runtime.
Its hook is `language: node`, so `pre-commit` builds that environment by fetching a node runtime into `~/.cache/pre-commit`, the way it already fetches the Go toolchain for `gitleaks`.
Nothing has to be installed on the machine for that, and the environment is reusable once built: `pre-commit run cspell --all-files` then runs the checker on demand, which is the only way anything here runs `cspell` outside the editor.
That last part is what the word list is waiting on: it was written by reading the repo and judging what the dictionaries already cover, and no run has confirmed it.

Running both means two lists of exceptions that drift apart, because each tool has to be told its own.
The order worth trying: leave `cspell` as an editor underline, and add the `cspell` hook only if a misspelling gets past `typos` or the word list turns out to need checking.
