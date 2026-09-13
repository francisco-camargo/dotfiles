---
name: repo-template-check
description: Check a repo against repo-template, the shared starting files for every project (ignore rules, line-ending rules, commit gates, security policy). Use when asked to check, compare, or align a repo with repo-template, or to bring the template's files into an existing repo.
---

# Check a repo against repo-template

[repo-template](https://github.com/francisco-camargo/repo-template) holds the files every project starts with, in its `template/` directory.
This skill compares an existing repo with those files and suggests what to adopt.
Keep a light touch: report, explain, and ask.
Change nothing in the repo until the user says yes, and never replace a file the repo already has.

## 1. Run the report

```bash
~/.claude/skills/repo-template-check/scripts/check.sh [project-dir]
```

The project defaults to the current directory.
The template comes from `$REPO_TEMPLATE`, else `~/git/repo-template`, else a fresh clone from GitHub; `--template <dir>` names another clone.

The script does the fixed checks and changes nothing:

- **Template:** the clone it used, its version, and whether that clone is behind its upstream or has uncommitted changes.
- **Project:** whether the pre-commit hook is installed and whether the GitHub repo is public or private.
- **Each template file:** missing, identical (ignoring line endings), or differs.
- **Each file that differs:** the template's lines the project's copy lacks, compared with whitespace and comments stripped.

If the clone is behind or has uncommitted changes, say so before going on, since the report reflects that state.

## 2. Offer the missing files

Present them in one question (AskUserQuestion, multiSelect), with a line on what each file does in its option's description.
Put everything needed to answer inside the question and its options, since text written just before a question may not reach the user.
Before asking, leave out or flag the ones that do not fit:

- **`SECURITY.md`** belongs in every repo, private ones included, so it is in place if a repo goes public. It sends reports through private vulnerability reporting, which GitHub offers only on public repos, so in a private repo say it does nothing until the repo is made public and reporting is turned on.
- **`.env.example`** does not fit a repo that already has the same file under another name, such as `.env.template`, or that reads no environment variables.
- **`.pre-commit-config.yaml`** brings gates that fail on existing problems; see step 4 before copying it.

Copy each chosen file without overwriting:

```bash
cp -n "<template>/<file>" "<project>/<file>"
```

## 3. Suggest changes to the files that differ

The script's list of lacking lines is a starting point, not a verdict.
Read both files, then for each file:

- **Check each lacking line** for a form the project already has. A broader pattern covers a narrower one (`.env*` covers `.env.*`), and an empty `"words": []` means nothing next to a filled word list.
- **Say what each real gap does** and whether this project seems to want it. repo-template's README and dotfiles' [docs/security.md](https://github.com/francisco-camargo/dotfiles/blob/main/docs/security.md) give the reasons behind the gates.
- **Point out a project line that means something different** from the template's. `* text eol=lf` treats every file as text, so binaries need rules of their own; `* text=auto eol=lf` lets git detect them.
- **Say what `eol=lf` would change**, here and when offering a missing `.gitattributes` in step 2, from `git ls-files --eol`. A file stored with CRLF (`i/crlf`) needs `git add --renormalize .` and a commit of its own. A file stored as LF but checked out as CRLF (`i/lf w/crlf`) comes back as LF on the next checkout, with nothing to commit.
- **Leave the project's own lines alone.** Python ignore rules, a word list, or an extra hook are the project's, not drift.

Suggest the user review the whole difference with `diff -u "<template>/<file>" "<project>/<file>"`, then offer to add the lines they choose.

## 4. After adopting the gates

When `.pre-commit-config.yaml` was copied or changed:

- Run `pre-commit install` if the report said the hook is not installed.
- Expect `pre-commit run --all-files` to fail at first: the whitespace and end-of-file fixers rewrite old files, and lychee reports links that were already broken. The fixes make a cleanup commit of their own.
- The gitleaks hook scans only staged changes, so suggest `gitleaks git` once to check the history.

Point at the GitHub settings in repo-template's README, under "Use it": push protection, a branch ruleset, and private vulnerability reporting.
A public repo needs them now; a private one needs them the day it is made public.

End with a message that repeats what was left out and why, and what still waits on the user, since explanations given between steps may not have reached them.

Commit nothing without the user; follow their commit conventions.
