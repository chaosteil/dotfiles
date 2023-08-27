#!/bin/bash

# git
stow git
git submodule update --init --recursive

# nvim
stow nvim
nvim +qall

# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
touch "$HOME/.local_paths"
stow zsh
stow starship

# terminal
stow kitty
