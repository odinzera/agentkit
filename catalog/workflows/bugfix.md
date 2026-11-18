---
name: bugfix
description: Reproduce, root-cause and fix a bug with a regression test
argument-hint: <bug description or issue link>
---

Fix this bug: $ARGUMENTS

1. **Reproduce** — find the smallest reliable reproduction. If you can't reproduce it, stop and report what you tried.
2. **Regression test** — write a test that fails because of the bug (test-writer agent if available).
3. **Root cause** — trace why it happens. Explain it in one or two sentences before changing code.
4. **Fix** — change the cause, not the symptom. Keep the diff minimal.
5. **Verify** — the new test passes and the full suite is still green.
6. **Report** — cause, fix, and any related places that may have the same bug.
