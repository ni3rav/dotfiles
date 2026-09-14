# dotfiles

repo: git@github.com:ni3rav/dotfiles.git

Each named directory is a stow package. It maps onto `$HOME` by prefix:

```
zsh     → ~/.zshrc ~/.zsh
git     → ~/.gitconfig
config  → ~/.config
local   → ~/.local/bin ~/.local/share/fonts
```

`dconf/` and `extra/` are not stowed.

# clone
git clone --recurse-submodules git@github.com:ni3rav/dotfiles.git ~/dotfiles
cd ~/dotfiles

# restore everything (fresh fedora)
stow local && restore-fedora

# apply configs only
stow zsh git config local

# restore gnome settings only
bash ~/dotfiles/dconf/restore-gnome.sh  # logout/login required

# fonts only
stow local && fc-cache -fv

# update submodules
git submodule update --init --recursive
