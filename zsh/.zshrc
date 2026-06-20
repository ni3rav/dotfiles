
# ==============================================================================
# 1. PATHS & BASIC ENVIRONMENT SETUP
# ==============================================================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.nub/bin:$PATH"

export PASSWORD_STORE_TYPE=basic

# ==============================================================================
# 2. OH MY ZSH INITIALIZATION
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"

# CRITICAL: We only use framework plugins that won't break keybindings.
# zsh-vi-mode, zsh-autosuggestions, and zsh-syntax-highlighting MUST be 
# removed from this array and initialized safely at the very bottom.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# ==============================================================================
# 3. INTERACTIVE TOOLS & ALIASES
# ==============================================================================
eval "$(zoxide init zsh)"

alias cd="z"
alias zconf="nvim ~/.zshrc"
alias reload="source ~/.zshrc"
alias shadcn="pnpm dlx shadcn@latest"
alias cat="bat"
alias ls="eza --long --icons"

# ==============================================================================
# 4. EXTERNAL RUNTIMES & COMPLETIONS (Cleaned Duplicates)
# ==============================================================================
# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Deno Environment
. "$HOME/.deno/env"

# Bun Runtimes & Completions
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# PNPM Package Manager Setup
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# ==============================================================================
# 5. PROMPT INITIALIZATION
# ==============================================================================
eval "$(oh-my-posh init zsh --config /home/ni3rav/.oh-my-posh-theme.json)"

# ==============================================================================
# 6. ADVANCED PLUGINS CONFIGURATION (Manual Loading Fixes Key Conflicts)
# ==============================================================================
# Step A: Load Vi-Mode manually (assumes cloning into custom folder or manual home)
if [ -f "$ZSH/custom/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]; then
    source "$ZSH/custom/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
elif [ -f "$HOME/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]; then
    source "$HOME/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
fi

# Step B: Secure zsh-autosuggestions inside Vi-mode's initialization lifecycle
# This prevents Vi-mode from wiping out your autocomplete key-bindings.
function zvm_after_init() {
    if [ -f "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
        source "$ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    elif [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
        source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
}

# Step C: Syntax Highlighting MUST run dead-last to safely wrap everything above
if [ -f "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
