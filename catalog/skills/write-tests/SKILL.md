---
name: write-tests
description: Adds meaningful tests for new or changed code using the project's existing test framework. Use when asked to add tests, improve coverage, or prove a bug fix.
---

# Writing tests

1. Find the existing test framework, layout and helpers (`package.json`, `pyproject.toml`, `go.mod`, existing `*_test`/`*.test.*` files). Match them; don't add a new framework.
2. For a bug fix, write the failing test first and confirm it fails for the right reason.
3. Cover: the happy path, each boundary, each error path, and one realistic regression case.
4. One behavior per test; name tests after the behavior (`returns_404_when_user_missing`).
5. Avoid mocking what you own; mock only slow or external boundaries.
6. Run the suite and report the real result, including any failures.
