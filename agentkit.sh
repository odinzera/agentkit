#!/usr/bin/env bash
# agentkit — one catalog of skills, agents and workflows, installed into
# Claude Code, OpenCode, Codex (or any target you add under lib/targets/).
set -euo pipefail

AK_HOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CATALOG=${AGENTKIT_CATALOG:-$AK_HOME/catalog}
KIND_DIRS=(skills agents workflows)
# shellcheck source=lib/common.sh
source "$AK_HOME/lib/common.sh"

usage() {
  cat <<EOF
${C_B}agentkit${C_0} — manage skills, agents and workflows for AI coding tools

${C_B}Usage:${C_0} ./agentkit.sh <command> [options]

${C_B}Commands:${C_0}
  list                     Show everything in the catalog
  install                  Install catalog items into the configured targets
  uninstall                Remove items agentkit installed (never touches other files)
  status                   Show what is installed where
  configure                Interactively write agentkit.conf
  new <kind> <name>        Scaffold a new skill | agent | workflow in the catalog
  import <path>            Copy an existing skill dir / agent .md / command .md into the catalog
  validate                 Check catalog items for required fields
  targets                  List available targets

${C_B}Options:${C_0}
  -t, --target LIST        Targets, comma-separated: $(available_targets | paste -sd, -) or all
  -g, --global             Install to user-level config dirs (default)
  -p, --project [DIR]      Install into a project (default: current dir)
  -k, --kinds LIST         Limit to: skills,agents,workflows
  -o, --only LIST          Only these item names (comma-separated)
  -x, --exclude LIST       Skip these item names
  -w, --with LIST          Also install these optional items (e.g. pen-tester)
  -l, --link               Symlink skills instead of copying (edits in the catalog go live)
  -f, --force              Replace files not managed by agentkit (originals are backed up)
  -n, --dry-run            Show what would happen
  -c, --config FILE        Config file (default: $AK_HOME/agentkit.conf)
  -h, --help               Show this help

${C_B}Examples:${C_0}
  ./agentkit.sh install                            # use agentkit.conf defaults
  ./agentkit.sh install -t claude,opencode -n      # preview for two tools
  ./agentkit.sh install -p ~/code/app -k skills    # only skills, into one project
  ./agentkit.sh install -o code-reviewer,feature   # just two items
  ./agentkit.sh install -w pen-tester              # everything + the optional pen-tester
  ./agentkit.sh uninstall -t all
EOF
}

available_targets() { local f; for f in "$AK_HOME"/lib/targets/*.sh; do basename "$f" .sh; done; }

# --- config ----------------------------------------------------------------
CONFIG_FILE=$AK_HOME/agentkit.conf
TARGETS="claude" SCOPE="global" PROJECT_DIR="" KINDS="skills agents workflows"
ONLY="" EXCLUDE="" WITH="" LINK_SKILLS=0

# pick up --config before loading, so flags still override the file
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  [[ ${args[i]} == -c || ${args[i]} == --config ]] && CONFIG_FILE=${args[i + 1]:-}
done
# shellcheck disable=SC1090
[[ -f $CONFIG_FILE ]] && source "$CONFIG_FILE"

CMD=${1:-help}; [[ $# -gt 0 ]] && shift
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -t | --target) TARGETS=$2; shift ;;
    -g | --global) SCOPE=global ;;
    -p | --project)
      SCOPE=project
      if [[ ${2:-} && $2 != -* ]]; then PROJECT_DIR=$2; shift; else PROJECT_DIR=$PWD; fi ;;
    -k | --kinds) KINDS=$2; shift ;;
    -o | --only) ONLY=$2; shift ;;
    -x | --exclude) EXCLUDE=$2; shift ;;
    -w | --with) WITH=$2; shift ;;
    -l | --link) LINK_SKILLS=1 ;;
    -f | --force) AK_FORCE=1 ;;
    -n | --dry-run) AK_DRY_RUN=1 ;;
    -c | --config) shift ;;
    -h | --help) usage; exit 0 ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *) POSITIONAL+=("$1") ;;
  esac
  shift
done

AK_SCOPE=$SCOPE
AK_LINK=$LINK_SKILLS
AK_PROJECT=$(cd "${PROJECT_DIR:-$PWD}" 2>/dev/null && pwd) || die "project dir not found: $PROJECT_DIR"
[[ $TARGETS == all ]] && TARGETS=$(available_targets | paste -sd' ')
TARGET_LIST=$(split_list "$TARGETS")
KIND_LIST=$(split_list "$KINDS")
ONLY_LIST=" $(split_list "$ONLY" | tr '\n' ' ') "
EXCLUDE_LIST=" $(split_list "$EXCLUDE" | tr '\n' ' ') "
WITH_LIST=" $(split_list "$WITH" | tr '\n' ' ') "

# --- catalog iteration -----------------------------------------------------
# items KIND -> lines of "name<TAB>path"
items() {
  local kind=$1 p name
  case $kind in
    skills) for p in "$CATALOG"/skills/*/; do
              [[ -f $p/SKILL.md ]] || continue; p=${p%/}; printf '%s\t%s\n' "$(basename "$p")" "$p"
            done ;;
    agents | workflows) for p in "$CATALOG/$kind"/*.md; do
              [[ -f $p ]] || continue
              name=$(fm_unquote "$(fm_get "$p" name)"); printf '%s\t%s\n' "${name:-$(basename "$p" .md)}" "$p"
            done ;;
  esac
}

selected() {
  local n=" ${1,,} "
  [[ $ONLY_LIST == "  " || $ONLY_LIST == *"$n"* ]] && [[ $EXCLUDE_LIST != *"$n"* ]]
}

item_file() { if [[ $1 == skills ]]; then echo "$2/SKILL.md"; else echo "$2"; fi; }
is_optional() { [[ $(fm_unquote "$(fm_get "$(item_file "$1" "$2")" optional)") == true ]]; }

# wanted KIND NAME PATH TARGET — should this item be acted on for this target?
wanted() {
  local kind=$1 name=$2 f n=" ${2,,} " only
  f=$(item_file "$kind" "$3")
  selected "$name" || return 1
  # optional items install only when asked for by name (--only / --with);
  # status and uninstall always consider them so nothing is left behind
  if [[ $AK_ACTION == install ]] && is_optional "$kind" "$3"; then
    [[ $ONLY_LIST == *"$n"* || $WITH_LIST == *"$n"* ]] || return 1
  fi
  only=$(fm_get "$f" targets)   # optional per-item target restriction
  [[ -z $only || " $(split_list "$only" | tr '\n' ' ') " == *" $4 "* ]]
}

describe() { # describe KIND PATH
  fm_unquote "$(fm_get "$(item_file "$1" "$2")" description)"
}

run_targets() {
  local t kind name path n=0
  for t in $TARGET_LIST; do
    [[ -f $AK_HOME/lib/targets/$t.sh ]] || die "unknown target '$t' (available: $(available_targets | paste -sd' '))"
    # shellcheck disable=SC1090
    source "$AK_HOME/lib/targets/$t.sh"
    ROOT=$("${t}_root")
    printf '\n%s%s%s %s(%s, %s)%s\n' "$C_B" "$t" "$C_0" "$C_D" "$AK_SCOPE" "$ROOT" "$C_0"
    for kind in $KIND_LIST; do
      [[ " ${KIND_DIRS[*]} " == *" $kind "* ]] || die "unknown kind '$kind' (use: ${KIND_DIRS[*]})"
      while IFS=$'\t' read -r name path; do
        wanted "$kind" "$name" "$path" "$t" || continue
        "${t}_${kind%s}" "$path" "$name"; n=$((n + 1))
      done < <(items "$kind")
    done
  done
  ((n > 0)) || warn "no catalog items matched the selection"
  ((AK_DRY_RUN)) && printf '\n%s(dry run: nothing was changed)%s\n' "$C_D" "$C_0"
  return 0
}

# --- commands --------------------------------------------------------------
cmd_list() {
  local kind name path
  for kind in $KIND_LIST; do
    printf '\n%s%s%s\n' "$C_B" "$kind" "$C_0"
    while IFS=$'\t' read -r name path; do
      selected "$name" || continue
      local tag="" tg; tg=$(fm_get "$(item_file "$kind" "$path")" targets)
      is_optional "$kind" "$path" && tag+="${C_Y}[optional]${C_0} "
      [[ -n $tg ]] && tag+="${C_Y}[$(fm_unquote "$tg") only]${C_0} "
      printf '  %-24s %s%s%s%s\n' "$name" "$tag" "$C_D" "$(describe "$kind" "$path" | cut -c1-90)" "$C_0"
    done < <(items "$kind")
  done
}

cmd_validate() {
  local kind name path f errs=0
  for kind in "${KIND_DIRS[@]}"; do
    while IFS=$'\t' read -r name path; do
      f=$path; [[ $kind == skills ]] && f=$path/SKILL.md
      local problems=()
      [[ $(head -1 "$f") == --- ]] || problems+=("missing frontmatter")
      [[ -n $(fm_get "$f" description) ]] || problems+=("missing description")
      [[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] || problems+=("name must be lowercase-kebab-case")
      if [[ $kind == skills ]]; then
        [[ $(fm_unquote "$(fm_get "$f" name)") == "$name" ]] || problems+=("frontmatter name must equal directory name")
      fi
      if ((${#problems[@]})); then
        errs=$((errs + 1)); warn "$kind/$name: $(IFS=';'; echo "${problems[*]}")"
      fi
    done < <(items "$kind")
  done
  ((errs == 0)) && info "catalog OK" || die "$errs item(s) with problems"
}

cmd_new() {
  local kind=${POSITIONAL[0]:-} name=${POSITIONAL[1]:-} dest
  [[ -n $kind && -n $name ]] || die "usage: new <skill|agent|workflow> <name>"
  [[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "name must be lowercase-kebab-case"
  case $kind in
    skill) dest=$CATALOG/skills/$name/SKILL.md ;;
    agent) dest=$CATALOG/agents/$name.md ;;
    workflow) dest=$CATALOG/workflows/$name.md ;;
    *) die "kind must be skill, agent or workflow" ;;
  esac
  [[ -e $dest ]] && die "already exists: $dest"
  mkdir -p "$(dirname "$dest")"
  case $kind in
    skill) cat >"$dest" <<EOF
---
name: $name
description: What this skill does and WHEN to use it. The agent reads this to decide whether to load the skill.
---

# ${name}

## When to use

## Steps

1.
EOF
    ;;
    agent) cat >"$dest" <<EOF
---
name: $name
description: What this agent is for and when the main agent should delegate to it.
# Portable tool names: read, write, edit, bash, grep, glob, webfetch, websearch. Omit for all tools.
tools: read, grep, glob
# Optional per-tool model overrides:
# claude_model: sonnet
# opencode_model: anthropic/claude-sonnet-5-5
---

You are a ... Your job is to ...
EOF
    ;;
    workflow) cat >"$dest" <<EOF
---
name: $name
description: One line shown in the slash-command menu.
argument-hint: [what to pass]
---

Goal: \$ARGUMENTS

1.
2.
EOF
    ;;
  esac
  info "created $dest"
}

cmd_import() {
  local src=${POSITIONAL[0]:-} name dest kind=""
  [[ -n $src && -e $src ]] || die "usage: import <skill-dir | agent.md | command.md>"
  src=$(cd "$(dirname "$src")" && pwd)/$(basename "$src")
  if [[ -d $src ]]; then
    [[ -f $src/SKILL.md ]] || die "$src has no SKILL.md"
    name=$(basename "$src"); dest=$CATALOG/skills/$name
    [[ -e $dest ]] && die "already in catalog: $dest"
    cp -R "$src" "$dest"; info "imported skill $name"; return
  fi
  # A .md file: agents live in an agents/ dir or declare tools; otherwise treat as workflow.
  case ${POSITIONAL[1]:-} in
    agent | workflow) kind=${POSITIONAL[1]} ;;
    "") if [[ $src == */agents/* || $src == */agent/* || -n $(fm_get "$src" tools) ]]; then kind=agent; else kind=workflow; fi ;;
    *) die "kind must be agent or workflow" ;;
  esac
  name=$(basename "$src" .md); dest=$CATALOG/${kind}s/$name.md
  [[ -e $dest ]] && die "already in catalog: $dest"
  {
    echo "---"
    echo "name: $name"
    echo "description: $(fm_get "$src" description)"
    local key v
    for key in tools model argument-hint; do
      v=$(fm_get "$src" "$key")
      [[ -n $v && $key == model ]] && key=claude_model
      [[ -n $v && $key == tools && $v == *"{"* ]] && v=""   # skip non-portable tool maps
      [[ -n $v ]] && echo "$key: ${v,,}"
    done
    echo "---"
    fm_body "$src"
  } >"$dest"
  info "imported $kind $name -> $dest (review the frontmatter)"
}

cmd_configure() {
  local t s k
  echo "Available targets: $(available_targets | paste -sd' ')"
  read -rp "Targets to install into [$TARGETS]: " t; t=${t:-$TARGETS}
  read -rp "Scope (global/project) [$SCOPE]: " s; s=${s:-$SCOPE}
  read -rp "Kinds [$KINDS]: " k; k=${k:-$KINDS}
  read -rp "Only these items (blank = all) [$ONLY]: " ONLY_IN; ONLY_IN=${ONLY_IN:-$ONLY}
  read -rp "Exclude items [$EXCLUDE]: " EX_IN; EX_IN=${EX_IN:-$EXCLUDE}
  local opt; opt=$(for kd in "${KIND_DIRS[@]}"; do items "$kd" | while IFS=$'\t' read -r n p; do is_optional "$kd" "$p" && echo "$n"; done; done | paste -sd' ')
  read -rp "Optional items to include (${opt:-none available}) [$WITH]: " WITH_IN; WITH_IN=${WITH_IN:-$WITH}
  read -rp "Symlink skills instead of copying? (0/1) [$LINK_SKILLS]: " L; L=${L:-$LINK_SKILLS}
  cat >"$CONFIG_FILE" <<EOF
# agentkit configuration — sourced by agentkit.sh. Command-line flags override these.
TARGETS="$t"          # $(available_targets | paste -sd' ') (space or comma separated) or all
SCOPE="$s"            # global | project
PROJECT_DIR=""        # used when SCOPE=project (blank = current dir)
KINDS="$k"
ONLY="$ONLY_IN"       # blank = everything in the catalog
EXCLUDE="$EX_IN"
WITH="$WITH_IN"       # optional items to include (e.g. pen-tester)
LINK_SKILLS=$L       # 1 = symlink skills to the catalog
EOF
  info "wrote $CONFIG_FILE"
}

case $CMD in
  list) cmd_list ;;
  install) AK_ACTION=install run_targets ;;
  uninstall) AK_ACTION=uninstall run_targets ;;
  status) AK_ACTION=status run_targets ;;
  validate) cmd_validate ;;
  new) cmd_new ;;
  import) cmd_import ;;
  configure) cmd_configure ;;
  targets) available_targets ;;
  help | -h | --help) usage ;;
  *) die "unknown command: $CMD (see --help)" ;;
esac
