---
name: code-review-checklist
description: A focused checklist for reviewing a diff or PR for correctness, security and maintainability. Use when asked to review code, a branch, or a pull request.
---

# Code review checklist

Review in this order and stop to report anything severe first.

1. **Correctness** — edge cases (empty, null, huge, concurrent), off-by-one, error paths, wrong assumptions about inputs.
2. **Security** — untrusted input reaching queries, shells, HTML or file paths; secrets in code; missing authz checks.
3. **Data** — migrations are reversible, no silent data loss, transactions where needed.
4. **Tests** — changed behavior is covered; tests assert outcomes, not implementation details.
5. **Readability** — names say what things are; no dead code; complexity is justified.

Report each finding as: `file:line — problem — concrete failure scenario — suggested fix`.
Rank by severity. Do not pad the list with style nits a linter would catch.
