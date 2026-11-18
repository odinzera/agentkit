# shellcheck shell=bash
# Claude Code adapter
#   skills    -> <root>/skills/<name>/SKILL.md
#   agents    -> <root>/agents/<name>.md      (subagents)
#   workflows -> <root>/commands/<name>.md    (slash commands: /<name>)

claude_root() {
  if [[ $AK_SCOPE == global ]]; then echo "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  else echo "$AK_PROJECT/.claude"; fi
}

_claude_tool() {
  case $1 in
    read) echo Read ;; write) echo Write ;; edit) echo Edit ;; bash) echo Bash ;;
    grep) echo Grep ;; glob) echo Glob ;; webfetch) echo WebFetch ;; websearch) echo WebSearch ;;
    *) echo "$1" ;;  # pass through anything else (e.g. MCP tool names)
  esac
}

claude_skill() { install_dir "$ROOT" "skills/$2" "$1"; }

claude_agent() {
  local f=$1 name=$2 tools model list=""
  tools=$(fm_get "$f" tools); model=$(fm_get "$f" claude_model); [[ -n $model ]] || model=$(fm_get "$f" model)
  if [[ -n $tools ]]; then
    local t; while read -r t; do list+="${list:+, }$(_claude_tool "$t")"; done < <(split_list "$tools")
  fi
  {
    echo "---"
    echo "name: $name"
    echo "description: $(fm_get "$f" description)"
    [[ -n $list ]] && echo "tools: $list"
    [[ -n $model ]] && echo "model: $model"
    echo "---"
    fm_body "$f"
  } | install_stream "$ROOT" "agents/$name.md"
}

claude_workflow() {
  local f=$1 name=$2 hint; hint=$(fm_get "$f" argument-hint)
  {
    echo "---"
    echo "description: $(fm_get "$f" description)"
    [[ -n $hint ]] && echo "argument-hint: $hint"
    echo "---"
    fm_body "$f"
  } | install_stream "$ROOT" "commands/$name.md"
}
