# shellcheck shell=bash
# OpenCode adapter
#   skills    -> <root>/skills/<name>/SKILL.md
#   agents    -> <root>/agents/<name>.md      (mode: subagent, invoke with @<name>)
#   workflows -> <root>/commands/<name>.md    (slash commands: /<name>)

opencode_root() {
  if [[ $AK_SCOPE == global ]]; then echo "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  else echo "$AK_PROJECT/.opencode"; fi
}

OC_TOOLS=(read write edit patch bash grep glob list webfetch)

opencode_skill() { install_dir "$ROOT" "skills/$2" "$1"; }

opencode_agent() {
  local f=$1 name=$2 tools model mode
  tools=$(fm_get "$f" tools); model=$(fm_get "$f" opencode_model)
  mode=$(fm_get "$f" opencode_mode); mode=${mode:-subagent}
  {
    echo "---"
    echo "description: $(fm_get "$f" description)"
    echo "mode: $mode"
    [[ -n $model ]] && echo "model: $model"
    if [[ -n $tools ]]; then
      # OpenCode enables every tool by default, so restrict by turning off the rest.
      local allowed t; allowed=" $(split_list "$tools" | tr '\n' ' ') "
      [[ $allowed == *" read "* ]] && allowed+="list "
      [[ $allowed == *" edit "* ]] && allowed+="patch "
      echo "tools:"
      for t in "${OC_TOOLS[@]}"; do [[ $allowed == *" $t "* ]] || echo "  $t: false"; done
    fi
    echo "---"
    fm_body "$f"
  } | install_stream "$ROOT" "agents/$name.md"
}

opencode_workflow() {
  local f=$1 name=$2 agent; agent=$(fm_get "$f" opencode_agent)
  {
    echo "---"
    echo "description: $(fm_get "$f" description)"
    [[ -n $agent ]] && echo "agent: $agent"
    echo "---"
    fm_body "$f"
  } | install_stream "$ROOT" "commands/$name.md"

  # opencode_primary_agent: true -> also expose the workflow as a primary agent
  # (switch to it with Tab), with $ARGUMENTS read as "the user's request".
  if [[ $(fm_unquote "$(fm_get "$f" opencode_primary_agent)") == true ]]; then
    {
      echo "---"
      echo "description: $(fm_get "$f" description)"
      echo "mode: primary"
      echo "---"
      fm_body "$f" | sed "s/\\\$ARGUMENTS/the user's request/g"
    } | install_stream "$ROOT" "agents/$name.md"
  fi
}
