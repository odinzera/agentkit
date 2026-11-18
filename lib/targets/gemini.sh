# shellcheck shell=bash
# Gemini CLI adapter
#   skills    -> <root>/skills/<name>/SKILL.md
#   agents    -> not supported, skipped
#   workflows -> <root>/commands/<name>.toml   (slash commands: /<name>; $ARGUMENTS -> {{args}})

gemini_root() {
  if [[ $AK_SCOPE == global ]]; then echo "${GEMINI_HOME:-$HOME/.gemini}"
  else echo "$AK_PROJECT/.gemini"; fi
}

gemini_skill() { install_dir "$ROOT" "skills/$2" "$1"; }

gemini_agent() { skip_once gemini_agents "gemini: agents are not supported, skipping"; }

_toml_basic() { local s; s=$(fm_unquote "$1"); s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '"%s"' "$s"; }

gemini_workflow() {
  local f=$1 name=$2 alias
  alias=$(fm_unquote "$(fm_get "$f" gemini_name)"); name=${alias:-$name}   # avoid built-in name clashes
  {
    echo "description = $(_toml_basic "$(fm_get "$f" description)")"
    echo
    # literal multi-line string: no escape processing, so backslashes in prompts survive
    echo "prompt = '''"
    fm_body "$f" | sed -e "s/\\\$ARGUMENTS/{{args}}/g" -e "s/'''/' ' '/g"
    echo "'''"
  } | install_stream "$ROOT" "commands/$name.toml"
}
