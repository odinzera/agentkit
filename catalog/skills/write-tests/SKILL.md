---
name: write-tests
description: Adds behavior-focused tests using the project's existing framework, writing a failing regression test first for bugs. Use when adding tests, improving coverage, proving a bug fix, or when new logic has no tests yet.
---

# Writing tests

## Overview
Tests are proof that behavior works and stays working. A test that can't fail proves nothing.

## When to use
- New or changed logic without tests
- A bug report: reproduce it as a failing test before fixing
- **Not** for running or repairing an existing suite (that's test-runner's job)

## Steps
1. **Match the project.** Find the framework, layout, helpers and run command (`package.json`, `pyproject.toml`, `go.mod`, existing test files). Never add a new framework.
2. **List behaviors**, not functions: happy path, each boundary (empty, zero, max, unicode, duplicates), each error path, and the realistic regression.
3. **Bug first:** write the test, run it, and confirm it fails *for the reported reason* before anyone touches the fix.
4. **One behavior per test**, named after it (`rejects_expired_token`). Arrange, act, assert.
5. **Mock only boundaries** you don't own or that are slow (network, clock, randomness). Never mock the unit under test.
6. **Run the suite** and report the real result, failures included.

## Common rationalizations
| Rationalization | Reality |
|---|---|
| "I'll add tests after it works" | Tests written after the fact assert whatever the code happens to do, including the bug. |
| "Mocking everything makes it a fast unit test" | It also makes it test the mocks. Real collaborators catch real bugs. |
| "Coverage is 90%, we're fine" | Coverage measures lines executed, not behaviors checked. |

## Red flags
- A new test that passed on its first run for a bug fix
- Assertions on private state or call counts instead of results
- `skip`, `only`, sleeps, or order-dependent tests

## Verification
- [ ] Each new test fails without the change and passes with it
- [ ] Edge and error paths are covered, not just the happy path
- [ ] Full suite run, result reported honestly
