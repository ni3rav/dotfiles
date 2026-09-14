# History ghost suggestions for zsh.
#
# Type a prefix → dim preview of a past command.
# Up/Down      → cycle matches (prefix first, then fuzzy).
# Right / End  → accept the preview.
# Tab          → untouched (native completion).
# Enter        → runs only what you typed; accept first if you want the preview.
#
# Fuzzy = case-insensitive substring, then subsequence whose first char
# matches a word start (so gst → git status, not cargo test).

if (( ${+_HS_LOADED} )); then
  _hs_bind_keys
  return
fi
typeset -g _HS_LOADED=1

: ${ZSH_HISTORY_SUGGEST_HIGHLIGHT:=fg=8}
: ${ZSH_HISTORY_SUGGEST_MAX:=40}
: ${ZSH_HISTORY_SUGGEST_SCAN:=4000}
: ${ZSH_HISTORY_SUGGEST_FUZZY_MIN:=2}

typeset -g _hs_suggestion _hs_query _hs_found
typeset -ga _hs_matches
typeset -gi _hs_index=1 _hs_locked=0

_hs_clear() {
  unset POSTDISPLAY _hs_suggestion
}

_hs_reset() {
  _hs_clear
  unset _hs_query
  _hs_matches=()
  _hs_index=1
}

# First char of query must start the line or a word.
_hs_fuzzy_eligible() {
  local q=$1 cmd=${(L)2}
  local ch=${(L)q[1]}
  [[ $cmd == "$ch"* || $cmd == *" $ch"* ]]
}

_hs_apply() {
  typeset -g _hs_suggestion=$1
  if [[ -z $BUFFER || -z $_hs_suggestion ]]; then
    unset POSTDISPLAY
    return
  fi
  if [[ ${_hs_suggestion:l} == "${BUFFER:l}"* ]]; then
    POSTDISPLAY=${_hs_suggestion:${#BUFFER}}
  else
    POSTDISPLAY="  → ${_hs_suggestion}"
  fi
}

_hs_best() {
  emulate -L zsh
  setopt EXTENDED_GLOB
  local prefix=$1
  unset _hs_found
  [[ -n $prefix ]] || return 1

  local ppat="(#i)${(b)prefix}*"
  local cmd="${history[(r)$ppat]}"
  if (( $#cmd > $#prefix )) && [[ $cmd != *$'\n'* ]]; then
    typeset -g _hs_found=$cmd
    return 0
  fi

  local cmd_i
  for cmd_i in "${(@)history[(R)$ppat]}"; do
    if (( $#cmd_i > $#prefix )) && [[ $cmd_i != *$'\n'* ]]; then
      typeset -g _hs_found=$cmd_i
      return 0
    fi
  done

  (( $#prefix >= ZSH_HISTORY_SUGGEST_FUZZY_MIN )) || return 1

  local spat="(#i)*${(b)prefix}*"
  for cmd_i in "${(@)history[(R)$spat]}"; do
    if (( $#cmd_i > $#prefix )) && [[ $cmd_i != *$'\n'* ]]; then
      typeset -g _hs_found=$cmd_i
      return 0
    fi
  done

  local fpat="(#i)"
  integer i
  for (( i = 1; i <= $#prefix; i++ )); do
    fpat+="*${(b)prefix[i]}"
  done
  fpat+="*"

  local -a keys
  keys=(${(Onk)history})
  integer max=$ZSH_HISTORY_SUGGEST_SCAN
  (( $#keys < max )) && max=$#keys
  for (( i = 1; i <= max; i++ )); do
    cmd_i=$history[$keys[i]]
    if (( $#cmd_i > $#prefix )) && [[ $cmd_i != *$'\n'* ]] \
      && [[ $cmd_i == ${~fpat} ]] && _hs_fuzzy_eligible "$prefix" "$cmd_i" \
      && [[ $cmd_i != ${~spat} ]]; then
      typeset -g _hs_found=$cmd_i
      return 0
    fi
  done
  return 1
}

_hs_collect() {
  emulate -L zsh
  setopt EXTENDED_GLOB
  local prefix=$1
  local -aU prefix_m substr_m fuzzy_m
  local ppat="(#i)${(b)prefix}*"
  local spat="(#i)*${(b)prefix}*"
  local fpat="(#i)"
  integer i
  for (( i = 1; i <= $#prefix; i++ )); do
    fpat+="*${(b)prefix[i]}"
  done
  fpat+="*"

  local -a keys
  keys=(${(Onk)history})
  integer max=$ZSH_HISTORY_SUGGEST_SCAN
  (( $#keys < max )) && max=$#keys
  local cmd

  for (( i = 1; i <= max; i++ )); do
    cmd=$history[$keys[i]]
    (( $#cmd > $#prefix )) || continue
    [[ $cmd == *$'\n'* ]] && continue

    if [[ $cmd == ${~ppat} ]]; then
      prefix_m+=("$cmd")
    elif (( $#prefix >= ZSH_HISTORY_SUGGEST_FUZZY_MIN )) && [[ $cmd == ${~spat} ]]; then
      substr_m+=("$cmd")
    elif (( $#prefix >= ZSH_HISTORY_SUGGEST_FUZZY_MIN )) \
      && [[ $cmd == ${~fpat} ]] && _hs_fuzzy_eligible "$prefix" "$cmd"; then
      fuzzy_m+=("$cmd")
    fi

    (( $#prefix_m >= ZSH_HISTORY_SUGGEST_MAX \
      && $#substr_m >= ZSH_HISTORY_SUGGEST_MAX \
      && $#fuzzy_m >= ZSH_HISTORY_SUGGEST_MAX )) && break
  done

  _hs_matches=(
    ${prefix_m[1,$ZSH_HISTORY_SUGGEST_MAX]}
    ${substr_m[1,$ZSH_HISTORY_SUGGEST_MAX]}
    ${fuzzy_m[1,$ZSH_HISTORY_SUGGEST_MAX]}
  )
}

_hs_ensure_matches() {
  [[ -n $BUFFER ]] || return 1
  if [[ $BUFFER == ${_hs_query:-} && ${#_hs_matches} -gt 0 ]]; then
    return 0
  fi
  _hs_query=$BUFFER
  _hs_collect "$BUFFER"
  _hs_index=1
  (( ${#_hs_matches} > 0 ))
}

_hs_accept() {
  [[ -n ${_hs_suggestion:-} ]] || return
  BUFFER=$_hs_suggestion
  CURSOR=$#BUFFER
  _hs_reset
}

_hs_on_redraw() {
  (( _hs_locked )) && return
  _hs_locked=1

  if [[ -z $BUFFER ]]; then
    _hs_reset
  elif [[ $BUFFER == ${_hs_query:-} && -n ${_hs_suggestion:-} ]]; then
    _hs_apply "$_hs_suggestion"
  else
    _hs_query=$BUFFER
    _hs_matches=()
    _hs_index=1
    if _hs_best "$BUFFER"; then
      _hs_apply "$_hs_found"
    else
      _hs_clear
    fi
  fi

  if [[ -n ${POSTDISPLAY:-} ]]; then
    region_highlight+=("${#BUFFER} $(( $#BUFFER + $#POSTDISPLAY )) ${ZSH_HISTORY_SUGGEST_HIGHLIGHT}")
  fi

  _hs_locked=0
}

_hs_up() {
  if [[ -z $BUFFER ]]; then
    zle .up-line-or-history
    return
  fi
  if ! _hs_ensure_matches; then
    zle .up-line-or-history
    return
  fi
  (( _hs_index++ ))
  (( _hs_index > ${#_hs_matches} )) && _hs_index=1
  _hs_apply "$_hs_matches[$_hs_index]"
  zle -R
}

_hs_down() {
  if [[ -z $BUFFER ]]; then
    zle .down-line-or-history
    return
  fi
  if ! _hs_ensure_matches; then
    zle .down-line-or-history
    return
  fi
  (( _hs_index-- ))
  (( _hs_index < 1 )) && _hs_index=${#_hs_matches}
  _hs_apply "$_hs_matches[$_hs_index]"
  zle -R
}

_hs_forward() {
  if [[ -n ${_hs_suggestion:-} && $CURSOR -eq $#BUFFER ]]; then
    _hs_accept
    zle -R
  else
    zle .forward-char
  fi
}

_hs_end() {
  if [[ -n ${_hs_suggestion:-} ]]; then
    _hs_accept
    zle -R
  else
    zle .end-of-line
  fi
}

zle -N _hs_up
zle -N _hs_down
zle -N _hs_forward
zle -N _hs_end

_hs_bind_keys() {
  local k
  for k in '^[[A' '^[OA'; do
    bindkey -M emacs $k _hs_up
    bindkey -M viins $k _hs_up
    (( $+functions[zvm_bindkey] )) && zvm_bindkey viins $k _hs_up
  done
  for k in '^[[B' '^[OB'; do
    bindkey -M emacs $k _hs_down
    bindkey -M viins $k _hs_down
    (( $+functions[zvm_bindkey] )) && zvm_bindkey viins $k _hs_down
  done
  for k in '^[[C' '^[OC'; do
    bindkey -M emacs $k _hs_forward
    bindkey -M viins $k _hs_forward
    (( $+functions[zvm_bindkey] )) && zvm_bindkey viins $k _hs_forward
  done
  for k in '^[[F' '^[OF' '^[[4~'; do
    bindkey -M emacs $k _hs_end
    bindkey -M viins $k _hs_end
    (( $+functions[zvm_bindkey] )) && zvm_bindkey viins $k _hs_end
  done
}

_hs_bind_keys
(( $+zvm_after_init_commands )) || typeset -ga zvm_after_init_commands
zvm_after_init_commands+=(_hs_bind_keys)

autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-pre-redraw _hs_on_redraw
