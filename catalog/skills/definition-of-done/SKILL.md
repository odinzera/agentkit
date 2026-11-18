---
name: definition-of-done
description: Applies a fixed, project-wide bar a change must clear before it is called done (verified behavior, tests, scope, docs, ship-readiness). Use when about to declare a task, feature or release complete, before opening a PR, or when asked "is this done?".
---

# Definition of Done

## Overview
Acceptance criteria say *what* to build; the Definition of Done says *how finished* it must be. Same bar every time, regardless of deadline.

## When to use
- Before saying "done", marking a task complete, opening a PR, or shipping
- **Not** a replacement for the task's own acceptance criteria. Both must hold.

## The bar

**Correct**
- [ ] Acceptance criteria met and verified by running the code, not just compiling it
- [ ] New behavior has tests that fail without the change
- [ ] Full suite, lint and build pass; no regressions

**Clean**
- [ ] Diff is scoped to the task: no drive-by refactors, debug output, dead or commented-out code
- [ ] No duplicated logic; names explain intent

**Integrated**
- [ ] Config, env vars, migrations and feature flags accounted for, with a rollback path for risky ones
- [ ] Public API / interface changes are backward compatible or flagged as breaking

**Documented**
- [ ] User-facing behavior and public interfaces documented; notable decisions recorded
- [ ] Docs describe the current state, not the change history

**Ready to ship**
- [ ] Untrusted input, auth and data handling reviewed for security
- [ ] New critical paths have logs/metrics
- [ ] A human has reviewed anything that needs sign-off

## Common rationalizations
| Rationalization | Reality |
|---|---|
| "Done, I just haven't run it yet" | Unverified is not done. |
| "Tests pass, so it's done" | Tests are one row of the bar. Docs, scope and rollback are others. |
| "We're behind, lower the bar this once" | A bar that bends under pressure is a suggestion. Cut scope instead. |

## Red flags
- "Should work" anywhere in a completion report
- Done declared with failing or skipped checks
- The bar renegotiated per task

## Verification
Report each section as ✅ met, ❌ not met (with what's missing), or N/A (with why). Anything ❌ means the work is not done.
