# shellcheck shell=bash
# Shared helpers: logging, frontmatter parsing, and managed file placement.

AK_ACTION=${AK_ACTION:-install}   # install | uninstall | status
AK_DRY_RUN=${AK_DRY_RUN:-0}
AK_FORCE=${AK_FORCE:-0}
AK_LINK=${AK_LINK:-0}
AK_STAMP=$(date +%Y%m%d-%H%M%S)
MANIFEST=.agentkit-manifest

if [[ -t 1 ]]; then C_G=$'\033[32m' C_Y=$'\033[33m' C_R=$'\033[31m' C_D=$'\033[2m' C_B=$'\033[1m' C_0=$'\033[0m'
else C_G='' C_Y='' C_R='' C_D='' C_B='' C_0=''; fi

info() { printf '  %s+%s %s\n' "$C_G" "$C_0" "$*"; }
note() { printf '  %s-%s %s\n' "$C_D" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
die()  { printf '%sagentkit:%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

# --- frontmatter -----------------------------------------------------------
# fm_get FILE KEY -> raw value of a top-level "key: value" line (quotes kept)
fm_get() {
  awk -v k="$2" '
    NR==1 { if ($0 !~ /^---[[:space:]]*$/) exit; next }
    /^---[[:space:]]*$/ { exit }
    index($0, k ":") == 1 { v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v; exit }
  ' "$1"
}
fm_unquote() { local v=$1; v=${v#\"}; v=${v%\"}; v=${v#\'}; v=${v%\'}; printf '%s' "$v"; }
# fm_body FILE -> everything after the frontmatter block
fm_body() {
  awk 'NR==1 && /^---[[:space:]]*$/ { f=1; next }
       f && /^---[[:space:]]*$/ { f=0; next }
       !f { print }' "$1"
}
# split_list "a, b c" -> one item per line, lowercased
split_list() { tr ',[:upper:]' ' [:lower:]' <<<"$1" | tr -s ' ' '\n' | sed '/^$/d'; }

# --- manifest --------------------------------------------------------------
# Each target root keeps a manifest of the relative paths agentkit wrote, so
# uninstall only ever touches files agentkit owns.
manifest_has() { grep -qxF "$2" "$1/$MANIFEST" 2>/dev/null; }
manifest_add() { manifest_has "$1" "$2" || printf '%s\n' "$2" >>"$1/$MANIFEST"; }
manifest_del() {
  [[ -f $1/$MANIFEST ]] || return 0
  grep -vxF "$2" "$1/$MANIFEST" >"$1/$MANIFEST.tmp" || true
  mv "$1/$MANIFEST.tmp" "$1/$MANIFEST"
  [[ -s $1/$MANIFEST ]] || rm -f "$1/$MANIFEST"
}

safe_rel() { [[ -n $1 && $1 != /* && $1 != *..* ]] || die "refusing unsafe path: $1"; }

# _place ROOT REL -> 0 if the caller should write ROOT/REL now, 1 otherwise.
# Handles status/uninstall/dry-run/conflict logic for every kind of item.
_place() {
  local root=$1 rel=$2 dest="$1/$2" managed=0 exists=0
  safe_rel "$rel"
  manifest_has "$root" "$rel" && managed=1
  [[ -e $dest || -L $dest ]] && exists=1

  case $AK_ACTION in
    status)
      if ((exists && managed)); then info "$rel"
      elif ((exists)); then warn "$rel ${C_D}(exists, not managed by agentkit)${C_0}"
      else note "$rel ${C_D}(not installed)${C_0}"; fi
      return 1 ;;
    uninstall)
      if ((managed)); then
        if ((AK_DRY_RUN)); then note "would remove $dest"
        else rm -rf -- "$dest"; manifest_del "$root" "$rel"; info "removed $dest"; fi
      fi
      return 1 ;;
  esac

  if ((exists && !managed)); then
    if ((!AK_FORCE)); then warn "skip $dest (exists, not managed by agentkit; use --force)"; return 1; fi
    if ((AK_DRY_RUN)); then note "would back up and replace $dest"; return 1; fi
    local bak="$root/.agentkit-backups/$AK_STAMP/$rel"
    mkdir -p "$(dirname "$bak")" && mv -- "$dest" "$bak"
    warn "backed up $dest -> $bak"
  fi
  if ((AK_DRY_RUN)); then note "would write $dest"; return 1; fi
  mkdir -p "$(dirname "$dest")"
  rm -rf -- "$dest"
  return 0
}

# install_dir ROOT REL SRC_DIR — copy (or symlink with --link) a directory
install_dir() {
  _place "$1" "$2" || return 0
  if ((AK_LINK)); then ln -s "$3" "$1/$2"; else cp -R "$3" "$1/$2"; fi
  manifest_add "$1" "$2"; info "$1/$2"
}

# install_stream ROOT REL < content — write generated content
install_stream() {
  if ! _place "$1" "$2"; then cat >/dev/null; return 0; fi
  cat >"$1/$2"
  manifest_add "$1" "$2"; info "$1/$2"
}

skip_once() { # skip_once KEY MESSAGE — print a warning only once per run
  local var="AK_SKIPPED_${1//[^a-zA-Z0-9]/_}"
  [[ -n ${!var:-} ]] && return 0
  printf -v "$var" 1; [[ $AK_ACTION == install ]] && warn "$2"
  return 0
}
