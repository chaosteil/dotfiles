#!/bin/bash

# git
stow git
stow jj

git submodule update --init --recursive

# nvim
stow nvim
nvim +qall

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
touch "$HOME/.local_paths"
stow zsh
stow starship

# fish
# --no-folding, or stow symlinks ~/.config/fish itself into this repo.
stow --no-folding fish
touch "$HOME/.config/fish/local.fish"

FISH_BIN=/opt/homebrew/bin/fish
grep -qxF "$FISH_BIN" /etc/shells || echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
[ "$SHELL" = "$FISH_BIN" ] || chsh -s "$FISH_BIN"

# terminal
stow ghostty
stow atuin
