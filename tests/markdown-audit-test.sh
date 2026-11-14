#!/usr/bin/env bash
# Run the markdown-audit skill's check.sh on a scratch repo with known
# problems, and check it reports each one and nothing it should skip.
#
#   tests/markdown-audit-test.sh
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
check_sh="$repo/claude/skills/markdown-audit/scripts/check.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
failed=0

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'ok    %s\n' "$name"
  else
    printf 'FAIL  %s\n' "$name"
    failed=1
  fi
}

says() { grep -qF -- "$1" "$tmp/out"; }
silent() { ! grep -qF -- "$1" "$tmp/out"; }
# The lines of one section of the report, between its heading and the next.
section() {
  awk -v h="  $1:" '$0 == h { on = 1; next } /^  [^ ]/ { on = 0 } on' "$tmp/out"
}
lists() { section "$1" | grep -qxF "    $2"; }
omits() { ! section "$1" | grep -qxF "    $2"; }

mkdir -p "$proj/docs" "$proj/plans"
cd "$proj"
# An empty template keeps a global init.templateDir from adding hooks.
git init --quiet --template=
git config core.autocrlf false
git config user.email test@example.com
git config user.name test

cat >README.md <<'EOF'
# Sample Project

Read [the guide](docs/guide.md) and the [plans](TODO.md).
Go [here](docs/guide.md) for more. See https://example.com too.
EOF
cat >docs/guide.md <<'EOF'
# Guide

**Where it goes.** It just works — mostly.

Cut "just" and "very" from prose.
It is `very` short.

```
just code
```

---

## Install On Windows

A sentence that wraps
onto a second line.
Two lines, each whole.

- A list item that wraps
  onto a second line.
- An item that ends in a colon:

Set up a new machine.
It works today.
EOF
cat >TODO.md <<'EOF'
# TODO

- [A plan](plans/linked.md): a thing, back in [the README](README.md).
- Back to [the top](TODO.md#todo).
- [A quiet plan](plans/quiet.md): links nowhere.
EOF
echo "# Quiet plan" >plans/quiet.md
echo "# Linked plan, back to [TODO](../TODO.md)" >plans/linked.md
echo "# Forgotten plan" >plans/forgotten.md
echo "# Nobody links here" >orphan.md
git add .
git commit --quiet -m fixture

"$check_sh" --no-pre-commit >"$tmp/out"

check "an em dash is a hit" says "docs/guide.md:3: no em dashes"
check "a bold title is a hit" says "docs/guide.md:3: headings and lists, not bold titles"
check "a filler word is a hit" says "docs/guide.md:3: filler words"
check "a word in quotes is not" silent "docs/guide.md:5: filler words"
check "a word in inline code is not" silent "docs/guide.md:6: filler words"
check "a word in a code block is not" silent "docs/guide.md:9:"
check "a fence with no language is a hit" says "docs/guide.md:8: code blocks name their language"
check "a horizontal rule is a hit" says "docs/guide.md:12: no horizontal rules"
check "a title-case heading is a hit" says "docs/guide.md:14: headings in sentence case"
check "a title-case title is a hit" says "README.md:1: headings in sentence case"
check "link text 'here' is a hit" says "README.md:4: link text names the target"
check "two sentences on a line are a hit" says "README.md:4: one sentence per line"
check "a hard-wrapped sentence is a hit" says "docs/guide.md:16: one sentence per line"
check "  ...and its last line is not" silent "docs/guide.md:17: one sentence per line"
check "a whole sentence is not" silent "docs/guide.md:18: one sentence per line"
check "a hard-wrapped list item is a hit" says "docs/guide.md:20: one sentence per line"
check "a line ending in a colon is not" silent "docs/guide.md:22: one sentence per line"
check "a link to its own file by name is flagged" \
  lists "links to their own file by name, where an anchor alone would do" TODO.md:4
check "'new' is not a dating word" silent "docs/guide.md:24: no details that go stale"
check "'today' is" says "docs/guide.md:25: no details that go stale"
check "a short file is flagged" says "orphan.md: 1 lines, under 20"
check "an orphan is unreachable" lists "unreachable from README.md" orphan.md
check "a linked plan is reachable" omits "unreachable from README.md" plans/linked.md
check "an orphan is linked from nothing" lists "linked from no other file" orphan.md
check "a file with no link up is flagged" lists "no link back to README.md or to a file linking here" docs/guide.md
check "a file linking up is not" omits "no link back to README.md or to a file linking here" TODO.md
check "a plan TODO.md links needs no link back" \
  omits "no link back to README.md or to a file linking here" plans/quiet.md
check "a plan TODO.md skips is flagged" lists "plans that TODO.md does not link to" plans/forgotten.md
check "a plan TODO.md links is not" omits "plans that TODO.md does not link to" plans/linked.md
check "no CLAUDE.md is reported" says "(no CLAUDE.md in the repo)"
check "no pre-commit config is reported" says "skipped (--no-pre-commit)"

if command -v pre-commit >/dev/null 2>&1; then
  cat >.pre-commit-config.yaml <<'EOF'
repos:
  - repo: local
    hooks:
      - id: strip-x
        name: strip x
        entry: sed -i s/xx//
        language: system
        files: \.md$
      - id: no-match
        name: no match
        entry: "true"
        language: system
        files: \.nomatch$
EOF
  git add .pre-commit-config.yaml
  git commit --quiet -m config
  echo "xx" >>orphan.md
  echo "an edit of my own" >>TODO.md
  git add orphan.md
  "$check_sh" >"$tmp/out" || true
  check "a dirty tree is reported" says "the working tree had uncommitted changes"
  check "a failing hook is reported" says "strip x"
  check "the fixers' change is shown" says "orphan.md |"
  check "an edit already there is not" silent "TODO.md |"
  check "a hook with no files to check is not shown" silent "no match"

  # A repo can keep its config elsewhere and name it at install time.
  git checkout --quiet -- .
  mkdir gates
  git mv .pre-commit-config.yaml gates/config.yaml
  git commit --quiet -am "move config"
  pre-commit install -c gates/config.yaml >/dev/null
  echo "xx" >>orphan.md
  "$check_sh" >"$tmp/out" || true
  check "the config the hook names is used" says "strip x"
else
  echo "skip  pre-commit is not installed"
fi

exit "$failed"
