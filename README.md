# agentkit

One catalog of **skills**, **agents** and **workflows**, installed into Claude Code, OpenCode, Codex CLI (or any tool you add an adapter for) by a single shell script.

```
./agentkit.sh configure          # pick targets/scope interactively (writes agentkit.conf)
./agentkit.sh install -n         # dry run
./agentkit.sh install            # install everything per agentkit.conf
./agentkit.sh status             # what's installed where
./agentkit.sh uninstall          # removes only what agentkit installed
```

## Layout

```
agentkit.sh            CLI
agentkit.conf          defaults (flags override)
lib/common.sh          frontmatter parsing, manifest, safe file placement
lib/targets/*.sh       one adapter per tool
catalog/
  skills/<name>/SKILL.md     + any supporting files
  agents/<name>.md
  workflows/<name>.md
```

## How items map to each tool

| Catalog    | Claude Code                   | OpenCode                          | Codex CLI                          |
|------------|-------------------------------|-----------------------------------|------------------------------------|
| skills     | `~/.claude/skills/<n>/`       | `~/.config/opencode/skills/<n>/`  | `~/.codex/skills/<n>/`             |
| agents     | `~/.claude/agents/<n>.md`     | `~/.config/opencode/agents/<n>.md` (subagent) | not supported, skipped |
| workflows  | `~/.claude/commands/<n>.md` → `/n` | `~/.config/opencode/commands/<n>.md` → `/n` | `~/.codex/prompts/<n>.md` → `/prompts:n` (global only) |

With `--project DIR` the roots become `DIR/.claude`, `DIR/.opencode` and `DIR/.codex`.
`CLAUDE_CONFIG_DIR`, `XDG_CONFIG_HOME` and `CODEX_HOME` are respected.

## Catalog formats

**Skill**: the standard `SKILL.md` (works as-is in all three tools):

```markdown
---
name: commit-message          # must equal the directory name
description: What it does and when to use it.
---
Instructions...
```

**Agent**: written once with portable fields, rendered per tool:

```markdown
---
name: code-reviewer
description: When the main agent should delegate to this.
tools: read, grep, glob, bash     # read write edit bash grep glob webfetch websearch; omit = all
claude_model: sonnet              # optional (alias: model)
opencode_model: anthropic/claude-sonnet-5-5   # optional
opencode_mode: subagent           # optional, default subagent
---
System prompt...
```

Claude gets `tools: Read, Grep, Glob, Bash`. OpenCode gets a `tools:` map that turns off everything not listed.

**Workflow**: a multi-step prompt installed as a slash command. `$ARGUMENTS` is replaced by whatever follows the command.

```markdown
---
name: bugfix
description: Shown in the command menu
argument-hint: <bug description>
opencode_agent: build             # optional
---
Fix this bug: $ARGUMENTS
1. ...
```

**Fields for any item:**

```yaml
optional: true                    # skipped unless named with --with / --only (or WITH= in agentkit.conf)
targets: opencode                 # only install into these targets
opencode_primary_agent: true      # workflows only: also install as an OpenCode primary agent (Tab to switch)
```

## The team

| Agent | Role |
|---|---|
| `explorer` | read-only search and mapping |
| `code-writer` | writes production code |
| `test-writer` | writes new tests and failing regression tests (test files only) |
| `test-runner` | runs the existing suite and fixes broken tests |
| `code-reviewer` | reviews the diff (read-only) |
| `pen-tester` | **on demand only**: security audit and safe confirmation against local or authorized targets. Not used by `/master` or any workflow; ask for it directly ("use the pen-tester on the auth module", or `@pen-tester` in OpenCode) |

**Master orchestrator.** `/master <task>` works out what kind of task it is and maps the relevant code. It plans, asking for your approval when the work is large or risky. It then hands each phase to the agents above, reviews the result at most 3 times, and reports.
It's a workflow rather than an agent because Claude Code subagents can't start other subagents, so the orchestrator has to run in the main conversation.
- Claude Code: `/master add rate limiting to the login endpoint`
- OpenCode: `/master …`, or press Tab to switch to the `master` primary agent
- Codex: `/prompts:master …` (no subagents there, so it runs every phase itself)

## Commands and options

```
list | install | uninstall | status | validate | targets
configure                      interactive config
new <skill|agent|workflow> <name>   scaffold in the catalog
import <path> [agent|workflow]      bring in an existing skill dir / agent / command file

-t claude,opencode | all     -g global (default)    -p [DIR] project
-k skills,agents,workflows   -o only,these          -x exclude,these     -w with,optional
-l symlink skills            -f force               -n dry run      -c config file
```

## Safety

- Each target root gets a `.agentkit-manifest`. Uninstall and re-install only touch paths listed there.
- Files you created yourself are **skipped** unless you pass `--force`. Then the original is moved to `<root>/.agentkit-backups/<timestamp>/` first. Uninstalling later removes agentkit's copy but leaves the backup, so restore it by hand if you want it back.
- `--link` symlinks skills to the catalog, so edits show up without reinstalling. Agents and workflows are always rendered copies, so re-run `install` after editing them.

## Adding another tool

Create `lib/targets/<tool>.sh` defining four functions (see `codex.sh` for the smallest example):

```bash
<tool>_root()      # print the config root for $AK_SCOPE (global|project; project dir is $AK_PROJECT)
<tool>_skill()     # $1 = skill dir,  $2 = name  -> install_dir "$ROOT" "rel/path" "$1"
<tool>_agent()     # $1 = agent .md,  $2 = name  -> render | install_stream "$ROOT" "rel/path"
<tool>_workflow()  # $1 = workflow .md, $2 = name
```

It's then usable as `-t <tool>` and is included in `-t all`. Helpers: `fm_get FILE KEY`, `fm_body FILE`, `split_list`, `skip_once`.
