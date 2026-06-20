export PATH="$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export UV_LINK_MODE=copy

eval "$(zoxide init zsh)"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

alias cd="z"
alias zconf="nvim ~/.zshrc"
alias reload="source ~/.zshrc"
alias shadcn="pnpm dlx shadcn@latest"
alias cat="bat"
alias ls="eza --long --icons"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

. "$HOME/.deno/env"

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# bun completions
[ -s "/home/ni3rav/.bun/_bun" ] && source "/home/ni3rav/.bun/_bun"
. "/home/ni3rav/.deno/env"

export PASSWORD_STORE_TYPE=basic
eval "$(oh-my-posh init zsh --config /home/ni3rav/.oh-my-posh-theme.json)"

# pnpm
export PNPM_HOME="/home/ni3rav/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# nub
export PATH="$HOME/.nub/bin:$PATH"
