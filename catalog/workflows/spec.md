---
name: spec
description: DEFINE — turn an idea into a written spec (SPEC.md) with testable acceptance criteria before any code
argument-hint: <idea or feature to specify>
---

Write a spec for: $ARGUMENTS

No code in this step. The output is a document a teammate could build from without asking you anything.

1. **Read first.** Check for an existing `SPEC.md` and skim the code the idea touches, so the spec fits what exists.
2. **Close the gaps.** If who it's for, what success looks like, or what is out of scope is unclear, ask the user, **one question at a time**, most important first. Stop asking once the answers wouldn't change the design.
3. **Write `SPEC.md`** at the repo root (if one exists for another feature, write `SPEC-<short-name>.md` instead):

   ```markdown
   # <Feature>
   Status: draft

   ## Problem
   Who has it, and why it matters now.

   ## Goals / Non-goals
   ## Requirements
   Numbered, each with acceptance criteria phrased so a test can check it:
   1. <requirement> — AC: given <state>, when <action>, then <observable result>
   ## Interfaces & data
   APIs, schemas, UI states, error cases.
   ## Constraints
   Performance, security, compatibility, dependencies.
   ## Risks & open questions
   ```

4. **Self-check.** Every requirement is testable, nothing in Goals lacks a requirement, and non-goals are explicit.
5. Show the spec and ask for approval. On approval change `Status: draft` to `Status: approved`. Next step: `/plan`.

Red flags: vague verbs ("handle", "support", "improve") with no acceptance criteria; solution details with no stated problem; a spec that only restates the request.
