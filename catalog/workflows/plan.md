---
name: plan
description: PLAN — break the approved spec into small, ordered, verifiable tasks (tasks/plan.md)
argument-hint: [spec file, default SPEC.md]
gemini_name: planning          # Gemini CLI has a built-in /plan
---

Plan the work for the spec: $ARGUMENTS (if empty, use `SPEC.md`; if there is no spec, stop and suggest `/spec`).

1. **Read the spec and the code** it touches. Use the explorer agent for wide searches.
2. **Slice vertically.** Each task delivers one testable piece of behavior end to end, small enough for a single reviewable commit (rule of thumb: under ~200 changed lines). Put risky or foundational tasks first.
3. **Write `tasks/plan.md`:**

   ```markdown
   Source spec: SPEC.md

   ## Tasks
   - [ ] T1 — <title>
     - Covers: requirement 1, 2
     - Files: src/...
     - Depends on: —
     - Done when: <acceptance check, e.g. "test X passes; GET /a returns 404 for unknown id">
   - [ ] T2 — ...

   ## Risks
   ```

4. **Check coverage.** Every spec requirement maps to at least one task; no task exists without a requirement (no "while we're here" work).
5. Show the plan and wait for approval. Next step: `/build` (one task) or `/build auto` (all tasks).
