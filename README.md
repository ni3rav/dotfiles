# dotfiles

repo: git@github.com:ni3rav/dotfiles.git

Each named directory is a stow package. It maps onto `$HOME` by prefix. The KDE layout file still names this machine's wallpaper files under `/home/nirav/stuff/wallpaper` and `/home/nirav/Downloads`.

```
zsh             → ~/.zshrc ~/.zsh
git             → ~/.gitconfig
starship        → ~/.config/starship.toml
ghostty         → ~/.config/ghostty
vicinae         → ~/.config/vicinae
code            → ~/.config/Code
cursor          → ~/.config/Cursor
fonts           → ~/.local/share/fonts
kde             → ~/.config/plasma-org.kde.plasma.desktop-appletsrc
                  ~/.config/plasmashellrc
                  ~/.config/kactivitymanagerdrc
                  ~/.config/kglobalshortcutsrc
                  ~/.local/share/applications/net.local.vicinae*.desktop
restore-fedora  → ~/.local/bin/restore-fedora
                  ~/.local/bin/shepherd
```

`extra/` is not stowed. It keeps an arkenfox `user.js`, a COSMIC palette, and a KDE shortcut export.

zsh plugins are git submodules (vi-mode, syntax-highlighting, autosuggestions). Clone with `--recurse-submodules`.

# clone
git clone --recurse-submodules git@github.com:ni3rav/dotfiles.git ~/dotfiles
cd ~/dotfiles

# restore everything (fresh fedora)
bash restore-fedora/.local/bin/restore-fedora

# apply configs only
stow zsh git starship ghostty vicinae code cursor fonts kde restore-fedora

# fonts only
stow fonts && fc-cache -fv

# update submodules
git submodule update --init --recursive
