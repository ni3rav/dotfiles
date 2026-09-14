# Ghost suggestions from commands that last succeeded (exit 0).
#
# Type a prefix → dim suffix of a matching successful command.
# Up/Down      → cycle other prefix matches.
# Right / End  → accept the preview (insert and normal).
# Tab          → untouched (native completion).
# Enter        → runs only what you typed; accept first if you want the preview.

if (( ${+_HS_LOADED} )); then
  _hs_setup_zle
  return
fi
typeset -g _HS_LOADED=1

: ${ZSH_HISTORY_SUGGEST_HIGHLIGHT:=fg=8}
: ${ZSH_HISTORY_SUGGEST_MAX:=40}
: ${ZSH_HISTORY_SUGGEST_SCAN:=4000}
: ${ZSH_HISTORY_SUGGEST_FILE:=${XDG_DATA_HOME:-$HOME/.local/share}/zsh-history-suggest/commands}

typeset -g _hs_suggestion _hs_query _hs_found _hs_pending
typeset -ga _hs_matches _hs_cmds
typeset -gA _hs_seen
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

_hs_unhighlight() {
  (( ${+region_highlight} )) || return
  region_highlight=( "${(@)region_highlight:#*memo=zsh-history-suggest*}" )
}

_hs_apply() {
  typeset -g _hs_suggestion=$1
  if [[ -n $BUFFER && -n $_hs_suggestion && ${_hs_suggestion:l} == "${BUFFER:l}"* ]]; then
    POSTDISPLAY=${_hs_suggestion:${#BUFFER}}
  else
    unset POSTDISPLAY _hs_suggestion
  fi
}

_hs_load() {
  emulate -L zsh
  _hs_cmds=()
  _hs_seen=()
  [[ -r $ZSH_HISTORY_SUGGEST_FILE ]] || return

  local -a raw
  raw=("${(@f)$(<$ZSH_HISTORY_SUGGEST_FILE)}")
  local line
  integer i
  for (( i = $#raw; i >= 1; i-- )); do
    line=$raw[i]
    [[ -n $line ]] || continue
    (( ${+_hs_seen[$line]} )) && continue
    _hs_seen[$line]=1
    _hs_cmds+=("$line")
    (( $#_hs_cmds >= ZSH_HISTORY_SUGGEST_SCAN )) && break
  done

  (( $#raw > ZSH_HISTORY_SUGGEST_SCAN * 2 )) && _hs_compact
}

_hs_compact() {
  emulate -L zsh
  local dir=${ZSH_HISTORY_SUGGEST_FILE:h}
  local tmp=$ZSH_HISTORY_SUGGEST_FILE.tmp.$$
  [[ -d $dir ]] || mkdir -p -- "$dir" || return
  local -a oldest
  oldest=("${(@Oa)_hs_cmds}")
  print -r -- "${(F)oldest}" >| "$tmp" && mv -f -- "$tmp" "$ZSH_HISTORY_SUGGEST_FILE"
}

_hs_record() {
  emulate -L zsh
  local cmd=$1
  [[ -n $cmd ]] || return
  [[ $cmd == [[:space:]]* || $cmd == *$'\n'* ]] && return

  if [[ ${_hs_cmds[1]-} == $cmd ]]; then
    return
  fi

  if (( ${+_hs_seen[$cmd]} )); then
    _hs_cmds=("$cmd" "${(@)_hs_cmds:#${(b)cmd}}")
  else
    _hs_cmds=("$cmd" "${_hs_cmds[@]}")
    _hs_seen[$cmd]=1
    if (( $#_hs_cmds > ZSH_HISTORY_SUGGEST_SCAN )); then
      local drop=${_hs_cmds[-1]}
      unset "_hs_seen[$drop]"
      _hs_cmds[-1]=()
    fi
  fi

  local dir=${ZSH_HISTORY_SUGGEST_FILE:h}
  [[ -d $dir ]] || mkdir -p -- "$dir" || return
  print -r -- "$cmd" >>| "$ZSH_HISTORY_SUGGEST_FILE"
}

_hs_preexec() {
  [[ -n ${1:-} ]] || return
  typeset -g _hs_pending="$1"
}

# Must run first in precmd so $? is still the previous command.
_hs_precmd() {
  local -i st=$?
  local cmd=${_hs_pending-}
  unset _hs_pending
  (( st == 0 )) || return
  [[ -n $cmd ]] || return
  _hs_record "$cmd"
}

_hs_best() {
  emulate -L zsh
  setopt EXTENDED_GLOB
  local prefix=$1 cmd
  unset _hs_found
  [[ -n $prefix ]] || return 1

  local ppat="(#i)${(b)prefix}*"
  for cmd in "${_hs_cmds[@]}"; do
    if (( $#cmd > $#prefix )) && [[ $cmd != *$'\n'* && $cmd == ${~ppat} ]]; then
      typeset -g _hs_found=$cmd
      return 0
    fi
  done
  return 1
}

_hs_collect() {
  emulate -L zsh
  setopt EXTENDED_GLOB
  local prefix=$1 cmd
  local -aU prefix_m
  local ppat="(#i)${(b)prefix}*"

  for cmd in "${_hs_cmds[@]}"; do
    if (( $#cmd > $#prefix )) && [[ $cmd != *$'\n'* && $cmd == ${~ppat} ]]; then
      prefix_m+=("$cmd")
      (( $#prefix_m >= ZSH_HISTORY_SUGGEST_MAX )) && break
    fi
  done

  _hs_matches=(${prefix_m[1,$ZSH_HISTORY_SUGGEST_MAX]})
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

_hs_in_normal() {
  [[ ${KEYMAP-} == vicmd || ${ZVM_MODE-} == n ]]
}

# Insert: cursor can sit past the last char. Normal: it sits on it.
_hs_at_eol() {
  (( CURSOR == $#BUFFER )) && return 0
  _hs_in_normal && (( $#BUFFER > 0 && CURSOR == $#BUFFER - 1 ))
}

_hs_accept() {
  [[ -n ${_hs_suggestion:-} ]] || return
  BUFFER=$_hs_suggestion
  if _hs_in_normal && (( $#BUFFER > 0 )); then
    CURSOR=$(( $#BUFFER - 1 ))
  else
    CURSOR=$#BUFFER
  fi
  _hs_reset
  _hs_unhighlight
}

_hs_on_redraw() {
  [[ -n ${WIDGET-} ]] || return
  # Mode switches already redraw; touching POSTDISPLAY here wraps the line.
  case $WIDGET in
    zvm_enter_*|zvm_exit_*|zvm_select_vi_mode|zvm_reset_prompt|vi-cmd-mode|vi-insert|vi-replace|reset-prompt|zle-keymap-select|zle-line-init)
      return
      ;;
  esac
  (( _hs_locked )) && return
  _hs_locked=1
  _hs_unhighlight

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
    region_highlight+=("${#BUFFER} $(( $#BUFFER + $#POSTDISPLAY )) ${ZSH_HISTORY_SUGGEST_HIGHLIGHT} memo=zsh-history-suggest")
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
  if [[ -n ${_hs_suggestion:-} ]] && _hs_at_eol; then
    _hs_accept
    zle -R
  elif _hs_in_normal; then
    zle .vi-forward-char
  else
    zle .forward-char
  fi
}

_hs_end() {
  if [[ -n ${_hs_suggestion:-} ]]; then
    _hs_accept
    zle -R
  elif _hs_in_normal; then
    zle .vi-end-of-line
  else
    zle .end-of-line
  fi
}

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
    bindkey -M vicmd $k _hs_forward
    (( $+functions[zvm_bindkey] )) && zvm_bindkey viins $k _hs_forward
  done
  for k in '^[[F' '^[OF' '^[[4~'; do
    bindkey -M emacs $k _hs_end
    bindkey -M viins $k _hs_end
    bindkey -M vicmd $k _hs_end
    (( $+functions[zvm_bindkey] )) && zvm_bindkey viins $k _hs_end
  done
}

# zsh-vi-mode runs `$(zle -l)` during precmd init. Creating
# zle-line-pre-redraw before that makes zsh 5.9 SIGSEGV in bin_zle_list.
_hs_setup_zle() {
  (( ${+_hs_zle_ready} )) && { _hs_bind_keys; return }
  typeset -gi _hs_zle_ready=1
  zle -N _hs_up
  zle -N _hs_down
  zle -N _hs_forward
  zle -N _hs_end
  zle -N _hs_on_redraw
  _hs_bind_keys
  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget zle-line-pre-redraw _hs_on_redraw
}

_hs_load

# Capture $? before starship / vi-mode precmds rewrite it.
typeset -ga precmd_functions preexec_functions
precmd_functions=(_hs_precmd ${precmd_functions:#_hs_precmd})
preexec_functions=(_hs_preexec ${preexec_functions:#_hs_preexec})

if (( $+functions[zvm_init] )); then
  (( $+zvm_after_init_commands )) || typeset -ga zvm_after_init_commands
  zvm_after_init_commands+=(_hs_setup_zle)
  # Re-apply vicmd arrows after zvm's first normal-mode lazy binds.
  (( $+zvm_after_lazy_keybindings_commands )) || typeset -ga zvm_after_lazy_keybindings_commands
  zvm_after_lazy_keybindings_commands+=(_hs_bind_keys)
else
  _hs_setup_zle
fi
