#!/usr/bin/env bash
# End-to-end tests for agentkit: every run uses a throwaway HOME, never the real one.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
AK=./agentkit.sh
pass=0 fail=0

sandbox() {
  SB=$(mktemp -d); export HOME=$SB XDG_CONFIG_HOME=$SB/.config
  unset CLAUDE_CONFIG_DIR CODEX_HOME GEMINI_HOME; export GRAPHIFY=0
}
ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$1"; }
check() { local name=$1; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }
has()  { grep -q -- "$2" "$1"; }
q()    { "$AK" "$@" -c /dev/null >/dev/null 2>&1; }   # -c /dev/null: ignore the repo's agentkit.conf
# pen-tester is on-demand only: no workflow may list it as a step or a team member
# shellcheck disable=SC2016  # backticks are literal markdown, not command substitution
no_pentester_delegation() { ! grep -qE '^[[:space:]]*[0-9]+\. \*\*pen-tester|^\| `pen-tester`' "$1"/*.md; }

echo "catalog"
check "validate passes" "$AK" validate

echo "install (claude)"
sandbox
q install -t claude
check "skill copied"            test -f "$HOME/.claude/skills/write-tests/SKILL.md"
check "agent rendered"          has "$HOME/.claude/agents/explorer.md" "^tools: Read, Grep, Glob$"
check "agent model mapped"      has "$HOME/.claude/agents/explorer.md" "^model: haiku$"
check "workflow is a command"   test -f "$HOME/.claude/commands/master.md"
check "commands are user-only"  has "$HOME/.claude/commands/build.md" "^disable-model-invocation: true$"
check "pen-tester installed"    test -f "$HOME/.claude/agents/pen-tester.md"
check "no workflow delegates to pen-tester" no_pentester_delegation catalog/workflows
check "manifest written"        test -s "$HOME/.claude/.agentkit-manifest"
check "reinstall is idempotent" q install -t claude

echo "conflicts"
sandbox
mkdir -p "$HOME/.claude/skills/write-tests"; echo mine >"$HOME/.claude/skills/write-tests/SKILL.md"
q install -t claude -k skills
check "unmanaged file kept"     has "$HOME/.claude/skills/write-tests/SKILL.md" "^mine$"
q install -t claude -k skills -o write-tests -f
check "--force backs up"        bash -c "grep -rqx mine '$HOME/.claude/.agentkit-backups'"
check "--force replaces"        has "$HOME/.claude/skills/write-tests/SKILL.md" "^name: write-tests"

echo "uninstall"
sandbox
q install -t all
q uninstall -t all
check "removes every file"      bash -c "[ -z \"\$(find '$HOME' -type f)\" ]"

echo "opencode"
sandbox
q install -t opencode
check "subagent mode"           has "$XDG_CONFIG_HOME/opencode/agents/code-reviewer.md" "^mode: subagent$"
check "read-only tools off"     has "$XDG_CONFIG_HOME/opencode/agents/code-reviewer.md" "^  write: false$"
check "master primary agent"    has "$XDG_CONFIG_HOME/opencode/agents/master.md" "^mode: primary$"
check "skills when alone"       test -d "$XDG_CONFIG_HOME/opencode/skills/write-tests"
q install -t claude,opencode
check "no duplicate skills with claude" bash -c "[ ! -e '$XDG_CONFIG_HOME/opencode/skills/write-tests' ]"

echo "gemini / codex"
sandbox
q install -t gemini,codex
check "gemini toml command"     has "$HOME/.gemini/commands/spec.toml" "^prompt = '''$"
check "gemini args placeholder" has "$HOME/.gemini/commands/spec.toml" "{{args}}"
check "gemini renames /plan"    test -f "$HOME/.gemini/commands/planning.toml"
check "gemini skills"           test -f "$HOME/.gemini/skills/definition-of-done/SKILL.md"
check "codex prompts"           test -f "$HOME/.codex/prompts/build.md"
check "codex skips agents"      bash -c "[ ! -e '$HOME/.codex/agents' ]"

echo "selection"
sandbox
q install -t claude -o explorer
check "--only installs one"     bash -c "[ \$(wc -l <'$HOME/.claude/.agentkit-manifest') -eq 1 ]"
check "dry run writes nothing"  bash -c "sb=\$(mktemp -d); HOME=\$sb $AK install -t claude -n -c /dev/null >/dev/null; [ -z \"\$(ls -A \$sb)\" ]"

echo
echo "$pass passed, $fail failed"
((fail == 0))
