---
name: ship
description: SHIP — run parallel pre-merge reviews, merge them into a GO / NO-GO decision with a rollback plan
argument-hint: [base branch or commit range]
---

Decide whether the current change is ready to merge or release. Range: $ARGUMENTS (default: `main...HEAD`, or staged changes if nothing is committed).

## Phase A — fan out (in parallel)

Start these agents **in the same turn** so they run concurrently. Each gets the range and returns a report only; none of them edits files or calls other agents:

1. **code-reviewer** — correctness, readability, architecture, security and performance findings, ranked by severity.
2. **test-runner** — run the full suite, lint and build; report results only, fix nothing.
3. **test-writer** — *analysis only, write no files*: list untested behavior in the change (happy path, edge cases, error paths).

If agents aren't available, do the three passes yourself one after another.

## Phase B — merge (in this session)

Deduplicate findings, then check what no agent covers:
- config/env vars, migrations and their rollback, feature flags
- logging/metrics for new critical paths
- docs, changelog and public API changes

Apply the standing bar from the definition-of-done skill if it's installed.

## Phase C — decision

```markdown
## Ship decision: GO | NO-GO

### Blockers (must fix)
- <source>: <finding> — file:line
### Should fix
### Accepted risks
- <risk> — <mitigation>
### Rollback plan
- Trigger: <signal that means roll back>
- Steps: <exact commands or actions>
```

Rules:
- Any failing test or build, or any critical finding, means **NO-GO** unless the user explicitly accepts the risk.
- No GO without a rollback plan.
- This workflow does not run a security pen test. If the change warrants one, tell the user to run the pen-tester agent separately.
