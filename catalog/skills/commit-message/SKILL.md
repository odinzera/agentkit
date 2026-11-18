---
name: commit-message
description: Writes Conventional Commits messages from the actual staged diff and splits mixed changes into separate commits. Use when committing, when asked for a commit message, or when summarizing staged changes.
---

# Commit messages

## Overview
A commit message is the only documentation most changes ever get. Write it from the diff, not from memory of what you meant to do.

## When to use
- Creating any commit, or asked to write/fix a commit message
- **Not** for PR descriptions or changelogs (those summarize many commits)

## Steps
1. Read `git diff --staged`. If nothing is staged, show `git status` and ask what to stage; never stage everything silently.
2. If the diff mixes unrelated changes (a fix plus a refactor plus formatting), propose splitting it and stage hunk groups separately.
3. Pick one type: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`.
4. Subject: `type(scope): imperative summary`, ≤72 chars, lowercase after the colon, no period.
5. Body only when the *why* isn't obvious from the subject: motivation, constraints, what was ruled out. Wrap at 72. Skip the how; the diff shows it.
6. Footers: `BREAKING CHANGE: <what breaks and how to migrate>`, `Fixes #123`, and any attribution lines the project requires.

## Common rationalizations
| Rationalization | Reality |
|---|---|
| "It's a small change, `fix stuff` is fine" | Future-you searching `git log` can't find "stuff". Small changes get precise subjects too. |
| "I'll describe everything I did" | A list of edits duplicates the diff. Explain why. |
| "It's all one feature, one commit is fine" | Bundled refactors make the feature impossible to revert on its own. |

## Red flags
- Subject says "and" (two changes in one commit)
- `wip`, `update`, `changes`, `misc` as the whole subject
- Message describes code that isn't in the diff

## Verification
- [ ] Every statement in the message is true of the staged diff
- [ ] One logical change per commit
- [ ] Breaking changes are flagged in a footer
