---
name: code-review-checklist
description: Reviews a diff or pull request across correctness, security, data safety, tests and readability, reporting only substantiated, severity-ranked findings. Use when asked to review code, a branch, a commit range or a pull request, or before merging your own change.
---

# Code review checklist

## Overview
A review exists to stop bugs and unmaintainable code from merging, not to restyle it. Every finding needs a concrete way it fails.

## When to use
- Reviewing any diff, branch or PR, including your own before asking someone else
- **Not** for whole-codebase audits (use a tech-debt or security audit instead)

## Steps
Go in this order; severe problems first.
1. **Understand intent.** Read the PR description/spec, then the surrounding code, before judging lines.
2. **Correctness.** Empty/null/huge inputs, off-by-one, concurrency and ordering, error paths, wrong assumptions about callers.
3. **Security.** Untrusted input reaching SQL, shells, HTML, file paths or URLs; authz on every new endpoint; secrets in code or logs.
4. **Data.** Migrations reversible; no silent data loss; transactions where partial writes would corrupt state.
5. **Tests.** Changed behavior is covered; tests assert outcomes, not implementation; no skipped or weakened tests.
6. **Readability & design.** Names, dead code, duplicated logic, abstractions with only one user.
7. **Verify each suspicion** by tracing the code path. Drop what you can't substantiate.

Report each as `severity — file:line — problem — failure scenario — fix`, with severities **Critical** (breaks prod / security), **Required** (must fix before merge), **Optional**, **Nit**.

## Common rationalizations
| Rationalization | Reality |
|---|---|
| "The tests pass, so it's correct" | Tests only cover what someone thought of. Read the edge cases yourself. |
| "More findings = better review" | Twenty nits bury the one real bug. Rank, and cap nits. |
| "It's probably fine, the author knows this code" | Familiarity is how blind spots survive. Check anyway. |

## Red flags
- Findings with no failure scenario ("this might be a problem")
- Style comments a linter or formatter would catch
- Approving without having read the tests

## Verification
- [ ] Every Critical/Required finding has a reproducible failure scenario
- [ ] Findings are ranked, most severe first
- [ ] Explicitly say so when nothing significant was found
