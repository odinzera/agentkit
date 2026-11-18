# shellcheck shell=bash
# OpenAI Codex CLI adapter
#   skills    -> <root>/skills/<name>/SKILL.md
#   agents    -> not supported (Codex has no subagent files) — skipped
#   workflows -> $CODEX_HOME/prompts/<name>.md (custom prompts: /prompts:<name>; global only)

codex_root() {
  if [[ $AK_SCOPE == global ]]; then echo "${CODEX_HOME:-$HOME/.codex}"
  else echo "$AK_PROJECT/.codex"; fi
}

codex_skill() { install_dir "$ROOT" "skills/$2" "$1"; }

codex_agent() { skip_once codex_agents "codex: agents are not supported, skipping"; }

codex_workflow() {
  local f=$1 name=$2 hint
  if [[ $AK_SCOPE != global ]]; then
    skip_once codex_wf "codex: custom prompts are global-only, skipping workflows for project scope"; return 0
  fi
  hint=$(fm_get "$f" argument-hint)
  {
    echo "---"
    echo "description: $(fm_get "$f" description)"
    [[ -n $hint ]] && echo "argument-hint: $hint"
    echo "---"
    fm_body "$f"
  } | install_stream "$ROOT" "prompts/$name.md"
}
