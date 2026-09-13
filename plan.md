# Plan: a repo for starting new repos

A new repo whose one job is to give a project its starting files, and to keep giving it the fixes made to those files afterwards.
This file plans it from inside dotfiles, because much of what it would hold lives here today.
Once the new repo exists, this plan moves there or goes away.

The name is not settled; `<template>` stands in for it below.

## What someone does with it

There are three shapes this could take, and the choice decides most of what follows.

| Shape | What the user does | What they end up with |
| --- | --- | --- |
| **The clone is the start** | Clone the repo, or press "Use this template" on GitHub, and start working in it | A copy of the template repo itself, including its own README, history, and anything about the template rather than the project |
| **Clone, then run a script** | Clone the template repo somewhere, run `new-repo.sh my-project`, and the script writes a new repo next to it | A clean new repo, plus a template clone left lying around that has to be pulled before the next use |
| **Copier fetches it** | Run one command naming the template; nothing is cloned by hand | A clean new repo, answers to a few questions recorded in it, and a way to pull later template fixes in |

The first shape is the simplest, and it pays for that.
Everything about the template comes along and has to be deleted by hand.
The new repo has no link back, so a fix to the template never reaches it.
And it cannot ask a question, so a Python project and a shell project get the same files.

The second shape leaves the template behind and can ask questions, but the new repo still has no link back.
It also puts a script from someone else's clone between the user and their new repo, which is the thing [asking before replacing a file](README.md#ask-before-replacing-a-file) is trying to make safe in dotfiles.

The third shape is the recommendation.
The session looks like this:

```sh
uvx copier copy --trust gh:francisco-camargo/<template> my-project
```

Copier asks its questions, writes the files into `my-project`, and runs the steps the template lists after copying, such as `git init` and `pre-commit install`.
Months later, inside that project:

```sh
uvx copier update
```

That pulls in whatever changed in the template since, merged with whatever the project changed itself.
`uvx` runs a tool from PyPI without installing it, so the user needs `uv` and `git` and nothing else.

What no file can do is change GitHub's settings: push protection, the branch ruleset, private vulnerability reporting.
Copier prints a message after copying, and that message is where those steps go, as the `gh api` commands already in [docs/security.md](docs/security.md#four-layers-and-what-each-one-misses).
Running them as a copy step instead is possible, but it would change a GitHub repo as a side effect of creating local files, and the user may not have created the GitHub repo yet.

## Copier

[Copier](https://copier.readthedocs.io/) generates a project from a template and can later update the project as the template changes.
It is a Python tool, needing Python 3.10 and git 2.27 or newer.

### How a template is built

- **`copier.yml`** at the template's root holds the questions and the settings.
- **`_subdirectory: template`** keeps the files a project receives in their own directory, so the template repo's own README, TODO and tests are never copied into a project.
- **Files ending in `.jinja`** are rendered, so `README.md.jinja` can use the project name from an answer. Files without the suffix are copied as they are.
- **Jinja in a file name** makes a file conditional on an answer, for instance a Python layer of the pre-commit config that only appears when the project uses Python.
- **`_skip_if_exists`** names files the project owns once they exist, such as `README.md`: copier writes them on the first copy and leaves their contents alone after.
- **`_tasks`** lists commands to run after copying. Copier refuses to run them unless the user passes `--trust`.
- **`_message_after_copy`** is the text printed at the end.

### How updating works

The project records its answers, and the template version it came from, in `.copier-answers.yml`, which gets committed.
`copier update` needs three things, in copier's words: the project "includes a valid .copier-answers.yml file", the template "is versioned with Git (with tags)", and the project "is versioned with Git".
The project's `git status` should also be clean.

Copier then does a three-way merge between the old template version, the new one, and the project as it stands.
A conflict shows up as inline markers, the same as in a `git merge`, or as `.rej` files if asked.
So the template has to be released with tags, `v0.1.0` and up, and an update moves a project from one tag to a later one.

### What it costs

- **Python.** dotfiles keeps Python out of its hooks and its install, because those run on every machine. Copier runs once per project, by a person, through `uvx`, so that rule does not reach it.
- **Jinja is harder to read** than a plain file. Keeping `.jinja` to the few files that need an answer, and leaving the rest plain, limits that.
- **"Use this template" on GitHub stops being useful**, because it would copy `copier.yml` and raw `.jinja` files. The template repo should not be marked as a GitHub template.
- **Releases need tags.** A fix is not available to `copier update` until it is tagged.

### Adopting a repo that already exists

The documentation describes creating and updating, and says little about taking over a repo copier did not create.
Running `copier copy` into an existing repo should ask before overwriting each file that differs, then write `.copier-answers.yml`, after which `copier update` works.
That needs a trial run before anything relies on it, starting with dotfiles itself.

## What a new project receives

| File | When | Where it comes from |
| --- | --- | --- |
| `README.md` | Always, then the project owns it | A skeleton with the project name |
| `.gitignore` | Always | The credentials and OS clutter sections of dotfiles' `.gitignore` |
| `.gitattributes` | Always | dotfiles' `.gitattributes` |
| `.editorconfig` | Always | New; dotfiles has none |
| `.env.example` | Always | New: variable names with no values, so the real `.env` never has to be committed |
| `SECURITY.md` | Always | New, as planned in [Add a SECURITY.md](README.md#add-a-securitymd) |
| `LICENSE` | On a question | A choice of license, or none |
| `.pre-commit-config.yaml` | Always, with a Python layer on a question | dotfiles' config for the base, the Python config in `francisco-camargo/francisco-camargo` for the rest |
| `scripts/check-anchors.sh` | Always | dotfiles, along with its hook |
| `cspell.json` | Always, with an empty word list | dotfiles' settings, without its words |
| `.claude/settings.json` | On a question | The project-level route to the gates, from [Merge `settings.json` instead of replacing it](README.md#merge-settingsjson-instead-of-replacing-it) |
| `.copier-answers.yml` | Always | Written by copier |

Few questions is the aim: the project name, whether it uses Python, a license, and whether to include the Claude Code gates.
Each extra question is a branch in the template that has to be tested.

## What moves out of dotfiles

| In dotfiles today | Goes to | What stays in dotfiles |
| --- | --- | --- |
| `.gitattributes` | The template | The same file, now received from the template |
| `.gitignore` | The template, for credentials and OS clutter | The `.claude.json` and `.credentials.json` lines |
| `.pre-commit-config.yaml` | The template | The same file, received from the template |
| `scripts/check-anchors.sh` | The template | The same file, received from the template |
| `cspell.json` | The template, for the settings | The word list |
| [Commit the reference, not the secret](docs/security.md#commit-the-reference-not-the-secret) | The template's documentation | A link |
| [Git history does not forget](docs/security.md#git-history-does-not-forget) | The template's documentation | A link |
| [The commit gates](docs/security.md#the-commit-gates) | The template's documentation | A link |
| [Four layers, and what each one misses](docs/security.md#four-layers-and-what-each-one-misses) | The template's documentation | A link |
| [Repo-local hooks, or global](docs/security.md#repo-local-hooks-or-global-and-the-trap-in-the-global-one) | The template's documentation | A link |
| [Shared repo scaffolding](README.md#shared-repo-scaffolding) | Replaced by the template | A link |
| [Consolidate the two pre-commit configs](README.md#consolidate-the-two-pre-commit-configs) | The template's TODO | Nothing |
| [Settle how spelling gets checked](README.md#settle-how-spelling-gets-checked) | The template's TODO | Nothing |
| [Add a SECURITY.md](README.md#add-a-securitymd) | The template builds it | The file, received from the template |

What stays in dotfiles is what concerns one person's machines rather than a project: `install.sh`, everything under `claude/`, the hooks, the skills, the standing instructions, and the security sections about `~/.claude` and about code that runs on every machine that installs it.

dotfiles becomes the first project adopted by the template.
That is what keeps one source of truth: the shared files are written once, in the template, and dotfiles receives them through `copier update` like any other project.

## Layout of the template repo

```
<template>/
  copier.yml
  README.md             what the template gives a project, and why
  TODO.md
  docs/
    security.md         the sections moved out of dotfiles
  template/             what a project receives
    README.md.jinja
    SECURITY.md.jinja
    .gitignore
    .gitattributes
    .editorconfig
    .env.example
    .pre-commit-config.yaml.jinja
    cspell.json
    scripts/check-anchors.sh
    {{ _copier_conf.answers_file }}.jinja
  .pre-commit-config.yaml   the template repo's own gates
```

The template repo runs its own gates on itself, so a broken hook config fails there before a project copies it.

## To settle first

- **The name.** It shows up in every `copier copy` command and every `.copier-answers.yml`, so renaming it later touches every project.
- **Whether the anchor check belongs in every project.** dotfiles' README calls it repo-specific; every project from the template will have Markdown with links, which argues the other way.
- **Global excludes against per-repo `.gitignore`.** [Global git config](README.md#global-git-config) plans a `core.excludesFile` that retires the copied `.gitignore`. OS clutter belongs in the global file, since it is about one person's machine; credentials and build output belong in each project, since they protect everyone who clones it.
- **Whether copy steps may run `git init` and `pre-commit install`.** They need `--trust`, which asks the user to trust the template with a shell. Printing the commands instead costs two lines of typing.

## Order of work

1. Create the template repo with the files above, the questions in `copier.yml`, and a `v0.1.0` tag.
2. Generate a scratch project, change the template, tag `v0.1.1`, and run `copier update` in the scratch project to see the merge work.
3. Adopt dotfiles: run `copier copy` into it, keep its own lines where the template differs, and commit `.copier-answers.yml`.
4. Move the documentation and TODO items listed above out of dotfiles, leaving links.
5. Adopt the other repos that repeat these files by hand, one at a time.
