autoload -Uz compinit
compinit

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.nub/bin:$PATH"

eval "$(zoxide init zsh)"

alias cd="z"
alias zconf="nvim ~/.zshrc"
alias reload="source ~/.zshrc"
alias shadcn="pnpm dlx shadcn@latest"
alias cat="bat"
alias ls="eza --long --icons"

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

source "$HOME/.deno/env"

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

function zvm_after_init() {
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
}

source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
