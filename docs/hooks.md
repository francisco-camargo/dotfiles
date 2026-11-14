# Hooks

The [README](../README.md#hooks) lists the gates; this page explains each one.

Each gate below is an entry in `hooks.PreToolUse` in `claude/settings.json`.
A `PreToolUse` hook runs before a Bash or PowerShell tool call and can let it through, force an approval prompt, or refuse it.
The git gate backs its hook with further layers of permission rules; the rest are the hook alone.

To drop a gate, delete its entry in `hooks.PreToolUse`.
To turn a refusal into a prompt, change that entry's `"permissionDecision": "deny"` to `"ask"`.

## Rules for every gate

Keep these when you edit a gate.

### `sed` and `grep` only

Use no `jq`, `node`, or `python`, none of which are reliably installed.
Keep it that way, or a hook will silently stop firing on a machine that lacks the dependency.

### Test the pattern after JSON escaping

Each pattern is a string inside `settings.json`, so an alternation written `\|\|` at a shell prompt has to survive as `\\|\\|`, and `\.` as `\\.`.
Get that wrong and the pattern still parses, still exits 0, and matches nothing.
Test the string pulled back out of `settings.json`, not the one typed into the shell.

Claude Code then turns each `\\` into `\` once more before the shell runs the hook, so a doubled backslash in the decoded string reaches `grep` single.
To match a literal backslash, write `[\\]` in the JSON: `grep` reads a backslash inside brackets as itself, and no layer changes it.

### A command can start on a later line

The hooks read the raw JSON payload, where a newline in a multi-line command arrives as the two characters `\n`.
A gate that anchors a command to the start or to `;`, `&&`, `|` must also accept `\n` before it, or the second line of a call slips through.

### A gate runs only when its command does

The `sed` and uv gates carry an `if` rule, `Bash(sed *)` or `Bash(py*)`, so Claude Code starts them only when some part of the call runs `sed` or a name starting with `py`.
Claude Code splits the call itself, so `sed -i` inside quotes, a commit message, or a heredoc does not start the gate.
An `if` rule names one tool, so each gate has a Bash handler and a PowerShell handler with the same command; `tests/hooks-test.sh` fails if the copies differ.

### Text after `git commit` belongs to the git gate

The `sed` and uv gates cut the command at `git … commit` before matching, so a commit message that mentions `sed -i` or starts a line with `python` goes through even when a real `sed` elsewhere in the call starts the gate.
The git gate already shows the whole command for approval.

### Run the test after a change

`tests/hooks-test.sh` runs each gate as written in `settings.json` against sample commands; run it after changing one.

## The git approval gate

This gate requires your approval before Claude runs `git commit` or `git push`.
It has three layers, because the first two have gaps:

1. **`hooks.PreToolUse`**: a sed+grep command that reads the command out of the tool payload and forces an approval prompt when it matches `git[^;&|]{0,60}(commit|push)`. It catches forms the permission rules below miss: an option before the subcommand, as in `git -C /repo commit`, and git run inside another shell, as in `bash -c 'git commit'`.
2. **`permissions.ask`**: rules for `Bash(git commit:*)`, `Bash(git push:*)` and the PowerShell equivalents. Claude Code checks them against each part of a chained command, so they catch `cd /repo && git commit`. `ask` rules beat `allow` rules, so a project cannot grant itself permission later.
3. **`autoMode.soft_deny`**: stops auto mode's classifier from approving a commit itself, and spells out that "save this" or "version this" is not authorization.

To tighten it from "prompt me" to "never, I'll run git myself", move the entries from `permissions.ask` to `permissions.deny`.

## The sed gate

This gate denies `sed` edits outright.
Unlike the git gate it does not prompt, because the answer is never yes.

sed rewrites a file by regex, and code is full of characters a regex reads as syntax: `.`, `*`, `[`, `$`, `/`.
A pattern that looks literal matches more than it says.
`s/old/new/g` then replaces every match on every line rather than the one that was meant, `-i` writes the result straight over the file, and the command exits 0 either way.
Run by hand that is survivable, because you read the diff before moving on.
Run as one step in a longer task it is not: the mangled line becomes the base for the next several edits, and by the time it surfaces the diff is hard to untangle.

The hook denies a sed invocation carrying `-i`, `--in-place`, or an `s///` substitution.
It leaves `sed -n '1,50p' file` alone, so paging a file still works.
The refusal names the alternatives, so the response is to use the `Edit` tool or write a short script, not to look for a way around the hook.

### It trims the payload before matching

This step took a second try to get right; keep it if you edit the gate.

The hook reads the command out of the tool payload with the same `sed -n 's/.*"command"...//p'` extraction as the git gate.
That extraction is greedy in one direction only: it strips everything before the command but leaves the rest of the JSON, including the `description` field, on the line.
Any description containing `files,` or `functions,` then reads as an `s,` substitution and blocks a harmless command.
The second `sed 's/"[,}].*$//'` cuts the line at the end of the command value, which stops it.

## The uv gate

This gate denies a bare `python`, `pythonw`, or `py`, and the first of those with any version suffix, such as `python3` or `python3.12`.
Like the sed gate it refuses outright, with no prompt, because the answer never changes: run it through `uv`.

The reason is not taste.
On this machine `python` and `python3` on `PATH` are symlinks to `AppInstallerPythonRedirector.exe`, the Microsoft Store redirector, which opens a Store page and runs nothing.
No Python is installed outside uv; the only real interpreter is the one under `%APPDATA%\uv\python\`.
So `python script.py` cannot succeed here, and trying costs a turn spent reading a failure that looks like a missing file rather than a missing interpreter.

The hook matches those names in command position: at the start of a line, or after `;`, `&&`, `||`, `|`, or `(`.
A deny rule such as `Bash(python *)` would also catch `cd src && python app.py`, since Claude Code checks each part of a chained command, but it refuses without saying what to run instead.
The hook's message is what makes it worth a hook.

It leaves alone anything under `uv run`, including `uv run python -c ...`, where `python` is an argument rather than the command.
It also leaves alone an explicit interpreter path such as `.venv/Scripts/python.exe`, which is a choice and not the habit being corrected, and `python` used as an argument or inside a filename: `which python`, `grep -r python src/`, `cat python_notes.md`.
`pytest` passes too, though it shares its first two letters with the `py` launcher.

The refusal names the `uv` forms to use, so the correction arrives in the same turn and the next attempt is `uv run`, not a hunt for the interpreter.

This gate prompted the rule to [test the pattern after JSON escaping](#test-the-pattern-after-json-escaping): the alternation `\|\|` and the escaped `\.` both had to be written into JSON doubled.

The gate does not cover `pip`.
`pip install` reaches for the same missing interpreter, and `uv pip` or `uv add` replaces it; leaving it out is a matter of scope, not a finding that it is safe.
