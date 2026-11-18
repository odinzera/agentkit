---
name: commit-message
description: Writes clear Conventional Commits messages from the staged diff. Use when the user asks to commit, write a commit message, or summarize staged changes.
---

# Commit messages

1. Run `git diff --staged` (fall back to `git diff` if nothing is staged and ask before staging).
2. Pick one type: feat, fix, refactor, perf, test, docs, build, ci, chore.
3. Subject: `type(scope): imperative summary`, at most 72 chars, no trailing period.
4. Body (only when the why isn't obvious): what changed and why, wrapped at 72 cols. Skip the how.
5. Add `BREAKING CHANGE:` footer when public behavior changes incompatibly.
6. If the diff mixes unrelated changes, propose splitting it into several commits instead.
