# agentkit

One catalog of **skills**, **agents** and **workflows**, installed into Claude Code, OpenCode, Codex CLI and Gemini CLI (or any tool you add an adapter for) by a single shell script.

```
  DEFINE        PLAN          BUILD         VERIFY        REVIEW        SHIP
 ┌───────┐    ┌───────┐    ┌───────┐    ┌───────┐    ┌───────┐    ┌───────┐
 │ Spec  │ ─▶ │ Tasks │ ─▶ │ Code  │ ─▶ │ Tests │ ─▶ │ Diff  │ ─▶ │GO/NOGO│
 └───────┘    └───────┘    └───────┘    └───────┘    └───────┘    └───────┘
  /spec        /plan        /build    (inside /build)  /ship  (parallel review)

  …or hand the whole thing to /master <task>
```

```
./agentkit.sh install -n         # dry run with agentkit.conf defaults
./agentkit.sh install            # install
./agentkit.sh status             # what's installed where
./agentkit.sh uninstall          # removes only what agentkit installed
./agentkit.sh configure          # pick targets/scope interactively
```

## What's in the catalog

**Workflows** (slash commands you trigger; Claude Code won't start them by itself)

| Command | Phase | What it does |
|---|---|---|
| `/spec <idea>` | define | Asks clarifying questions one at a time, writes `SPEC.md` with testable acceptance criteria |
| `/plan` | plan | Breaks the spec into small vertical tasks in `tasks/plan.md`, each with a "done when" check |
| `/build` · `/build auto` | build + verify | Next task test-first (red → green → full suite → one commit). `auto` runs every task after a single approval and stops on anything risky |
| `/ship [range]` | review + ship | Runs code-reviewer, test-runner and a test-gap analysis **in parallel**, merges them into GO / NO-GO with a rollback plan |
| `/master <task>` | all | Orchestrator: triage → recon → plan → build → verify → review, delegating each phase |
| `/feature`, `/bugfix` | shortcuts | Lighter single-pass versions for everyday work |
| `/release-notes` | ship | Drafts user-facing notes from git history |

**Agents**

| Agent | Role |
|---|---|
| `explorer` | read-only search and code mapping |
| `code-writer` | writes production code |
| `test-writer` | writes new tests and failing regression tests (test files only); analysis-only mode for `/ship` |
| `test-runner` | runs the existing suite and fixes broken tests |
| `code-reviewer` | severity-ranked review of a diff (read-only) |
| `pen-tester` | **on demand only.** Security audit plus safe confirmation against local or authorized targets. No workflow uses it; ask for it directly ("use the pen-tester on the auth module", or `@pen-tester` in OpenCode) |

**Skills**: `commit-message`, `code-review-checklist`, `write-tests`, `definition-of-done`

### Orchestration rules

- **Only the main session (or a slash command) orchestrates.** Agents return reports; they never call each other. (Claude Code subagents can't start subagents anyway, which is why `/master` is a workflow.)
- **Parallel only when independent.** Reviews of the same diff fan out in one turn. Red → green → verify stays sequential.
- **Direct beats orchestrated.** "Review this file" goes straight to `code-reviewer`. Use `/master` when there are several phases.

## How items map to each tool

| Catalog | Claude Code | OpenCode | Codex CLI | Gemini CLI |
|---|---|---|---|---|
| skills | `~/.claude/skills/<n>/` | `~/.config/opencode/skills/<n>/` ¹ | `~/.codex/skills/<n>/` | `~/.gemini/skills/<n>/` |
| agents | `~/.claude/agents/<n>.md` | `~/.config/opencode/agents/<n>.md` | skipped | skipped |
| workflows | `~/.claude/commands/<n>.md` | `~/.config/opencode/commands/<n>.md` | `~/.codex/prompts/<n>.md` (global only) | `~/.gemini/commands/<n>.toml` |

¹ OpenCode also reads `.claude/skills`, so when Claude is a target too, agentkit skips OpenCode's copy (and removes one left by an older install) so skills aren't loaded twice.

With `--project DIR` the roots become `DIR/.claude`, `DIR/.opencode`, `DIR/.codex`, `DIR/.gemini`. `CLAUDE_CONFIG_DIR`, `XDG_CONFIG_HOME`, `CODEX_HOME` and `GEMINI_HOME` are respected.

## Writing catalog items

`./agentkit.sh new skill|agent|workflow <name>` scaffolds one. `./agentkit.sh validate` checks them.

**Skill**: standard `SKILL.md`, portable as-is. Only the Agent Skills spec keys are allowed at the top level (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`). The description says what it does **and** "Use when …", since that line is all an agent sees before deciding to load it. Don't summarize the steps in it. Recommended body:

```
Overview · When to use (and when not) · Steps · Common rationalizations · Red flags · Verification
```

The *Common rationalizations* table (the excuse an agent uses to skip a step, and why it's wrong) and the *Red flags* list are what keep agents from quietly cutting corners.

**Agent**: portable fields, rendered per tool:

```yaml
---
name: code-reviewer
description: When the main agent should delegate to this.
tools: read, grep, glob, bash     # read write edit bash grep glob webfetch websearch; omit = all
claude_model: sonnet              # optional (alias: model)
opencode_model: anthropic/claude-sonnet-5-5   # optional
opencode_mode: subagent           # optional: subagent (default) | primary | all
---
System prompt...
```

**Workflow**: a prompt installed as a slash command. `$ARGUMENTS` is what follows the command (`{{args}}` on Gemini).

```yaml
---
name: build
description: Shown in the command menu
argument-hint: [auto]
model_invocable: true             # optional: let Claude start it by itself (default: user-only)
opencode_primary_agent: true      # optional: also an OpenCode primary agent (Tab to switch)
opencode_agent: build             # optional: which OpenCode agent runs the command
gemini_name: planning             # optional: different command name on Gemini (avoids built-ins)
---
```

**Any item:** `optional: true` (installed only via `--with name` / `WITH=`), `targets: claude,opencode` (install only there).

## Commands and options

```
list | install | uninstall | status | validate | targets | configure
new <skill|agent|workflow> <name>       import <path> [agent|workflow]

-t claude,opencode,codex,gemini | all   -g global (default)   -p [DIR] project
-k skills,agents,workflows   -o only,these   -x exclude,these   -w with,optional
-l symlink skills            -f force        -n dry run         -c config file
```

## Safety

- Each target root has a `.agentkit-manifest`; uninstall and reinstall only touch paths listed there.
- Files you created yourself are skipped unless you pass `--force`; then the original is moved to `<root>/.agentkit-backups/<timestamp>/` first.
- `--link` symlinks skills so catalog edits go live; agents and workflows are rendered, so re-run `install` after editing them.

## Development

```
./agentkit.sh validate    # catalog lint
./tests/run.sh            # end-to-end tests in throwaway HOME dirs
```

CI (`.github/workflows/ci.yml`) runs shellcheck, validate and the tests on every push.

**Adding a tool:** create `lib/targets/<tool>.sh` with `<tool>_root`, `<tool>_skill`, `<tool>_agent` and `<tool>_workflow` (see `gemini.sh`). It's then available as `-t <tool>` and in `-t all`. Helpers: `fm_get FILE KEY`, `fm_body FILE`, `split_list`, `skip_once`, `install_dir`, `install_stream`.

## Credits

The lifecycle commands, skill anatomy (rationalizations / red flags / verification), definition of done and orchestration rules are inspired by [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT). All text here is original.
