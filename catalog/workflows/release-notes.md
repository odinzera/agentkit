---
name: release-notes
description: Draft release notes from git history since the last tag
argument-hint: [since-ref]
---

Draft release notes. Optional starting ref: $ARGUMENTS

1. Find the range: use `$ARGUMENTS` if given, else `git describe --tags --abbrev=0`.
2. Read `git log --no-merges <range>..HEAD` and the merged PR titles.
3. Group into: Breaking changes, Features, Fixes, Other. Drop pure chores and CI noise.
4. Write each entry for users, not developers: what they can now do or what no longer breaks.
5. Suggest the next semantic version based on the contents.
