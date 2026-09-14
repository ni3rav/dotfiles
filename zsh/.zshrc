autoload -Uz compinit
compinit

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.nub/bin:$PATH"
export EDITOR="vi"
# History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

eval "$(zoxide init zsh)"

alias cd="z"
alias zconf="nvim ~/.zshrc"
alias reload="source ~/.zshrc"
alias shadcn="pnpm dlx shadcn@latest"
alias cat="bat"
alias ls="eza --long --icons --classify=auto"
alias glo="git log --oneline --graph"
alias vi="nvim"

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"


export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

eval "$(starship init zsh)"

source ~/.zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
# add-zle-hook-widget before zvm_init makes zsh 5.9 SIGSEGV in `$(zle -l)`.
zvm_after_init_commands+=(
  'source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
)
source ~/.zsh/plugins/zsh-history-suggest/zsh-history-suggest.plugin.zsh

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

. "$HOME/.cargo/env"
