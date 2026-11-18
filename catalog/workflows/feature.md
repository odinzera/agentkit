---
name: feature
description: Plan, implement, test and review a feature end to end
argument-hint: <feature description>
---

Implement this feature: $ARGUMENTS

1. **Understand** — read the relevant code. If requirements are ambiguous in a way that changes the design, ask before writing code.
2. **Plan** — write a short plan: files to touch, data/API changes, tests to add. Keep it to what's needed.
3. **Implement** — in small steps, keeping the build green after each (hand this to the code-writer agent if available).
4. **Test** — add tests for the new behavior (test-writer agent if available), then run the full suite (test-runner agent).
5. **Review** — re-read the full diff as a reviewer would (use the code-reviewer agent if available) and fix what it finds.
6. **Summarize** — what changed, how it was verified, anything left open.
