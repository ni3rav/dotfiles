# dotfiles

repo: git@github.com:ni3rav/dotfiles.git

# clone
git clone --recurse-submodules git@github.com:ni3rav/dotfiles.git ~/dotfiles
cd ~/dotfiles

# restore everything (fresh fedora)
stow scripts && restore-fedora

# apply configs only
stow zsh tmux git posh config fonts scripts local

# restore gnome settings only
bash ~/dotfiles/dconf/restore-gnome.sh  # logout/login required

# fonts only
stow fonts && fc-cache -fv

# update submodules
git submodule update --init --recursive

