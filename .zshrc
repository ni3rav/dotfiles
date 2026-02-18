export PATH="$HOME/.local/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
export UV_LINK_MODE=copy

eval "$(zoxide init zsh)"

ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

alias cd="z"
alias zconf="nvim ~/.zshrc"
alias reload="source ~/.zshrc"
alias shadcn="pnpm dlx shadcn@latest"
alias cat="bat"

eval "$(oh-my-posh init zsh --config /home/ni3rav/.oh-my-posh-theme.json)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

. "/home/ni3rav/.deno/env"

# bun completions
[ -s "/home/ni3rav/.bun/_bun" ] && source "/home/ni3rav/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode (fixed ni4rav → ni3rav)
export PATH="$HOME/.opencode/bin:$PATH"

# Go (added)
export PATH="$PATH:$HOME/go/bin"

