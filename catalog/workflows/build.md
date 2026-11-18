---
name: build
description: BUILD — implement the next planned task test-first and commit it; "/build auto" runs the whole plan after one approval
argument-hint: [auto]
---

Mode: `$ARGUMENTS` — `auto` (or `all`) runs every pending task; anything else implements only the next one.

## Before starting

1. **Need a plan.** Read `tasks/plan.md`. If it's missing, stop and suggest `/plan` (or, in auto mode, generate it from the spec and get approval first). Don't invent requirements.
2. **Clean baseline.** Run `git status --porcelain`. If there are uncommitted changes besides `SPEC*.md` and `tasks/`, stop and ask whether to commit, stash or keep them, so per-task commits never swallow unrelated work.
3. **Auto mode only:** show the pending tasks and wait for a clear "yes/go/approve". A hedge ("looks fine I guess") is not approval. This is the only checkpoint.

## For each task

1. Read its "Done when" criteria and the relevant code.
2. **Red** — write a failing test for the behavior (test-writer agent if available) and confirm it fails for the right reason.
3. **Green** — implement the minimum to pass (code-writer agent if available).
4. **Verify** — run the full suite and the build (test-runner agent). Fix regressions before moving on.
5. **Commit** — stage only the files this task touched (never a blind `git add -A`), one commit per task, conventional message.
6. Tick the task in `tasks/plan.md`. Default mode: stop here and report.

## Stop and ask (even in auto mode) when

- a test or the build can't be made green without an obvious fix
- the spec is ambiguous or a task needs a decision it doesn't cover
- the task is risky or hard to undo: auth/permissions, payments, destructive migrations, deletions, secrets, deploys

## Finish

Report tasks completed, tests added, commits made, and anything skipped or flagged. Next step: `/ship`.
