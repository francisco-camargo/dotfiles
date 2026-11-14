# Plan: split standing instructions between CLAUDE.md and skills

## Goal

When a set of instructions outgrows `CLAUDE.md`, move its long form into a skill and leave a short core in `CLAUDE.md` that points at it.

## Why

`CLAUDE.md` is read in every session, so every entry has to earn that.
[What belongs here, and what belongs in a skill](../docs/standing-instructions.md#what-belongs-here-and-what-belongs-in-a-skill) makes the case.
Nothing needs splitting while `CLAUDE.md` stays short; a full writing style guide is the likely first case, with review checklists, commit conventions, and diagram style behind it.

## Steps

- [ ] Pick the first set of instructions to move, once one outgrows `CLAUDE.md`.
- [ ] Write its skill, and cut `CLAUDE.md` to a short core that points at it.
- [ ] Check over a few sessions that the skill loads when its subject comes up, without being asked for.

## Docs to update

- [ ] [docs/standing-instructions.md](../docs/standing-instructions.md): where the line fell, and why.
- [ ] `README.md`: the skill, in the file table and the skills list.

## Updates to send

None.

## Open questions

- **Where the line falls:** what stays in the short core, and what moves.
- **Triggering:** whether a skill's `description` loads it reliably for prose work, which is a vaguer trigger than "render this Markdown to PDF".
- **One skill or several:** a skill per subject, or one `house-style` skill for all of it.
- **The structure opinion:** whether the [Markdown audit plan](markdown-audit.md)'s opinion on how a repo's Markdown fits together becomes the style skill's first part.

## Done when

`CLAUDE.md` holds a short core for the moved instructions, and Claude loads the skill when its subject comes up without being asked for it.
