#!/usr/bin/env bash

# git
stow git
git submodule update --init --recursive

# nvim
stow nvim
nvim +PlugInstall +qall

# zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
touch "$HOME/.local_paths"
stow zsh

stow i3
stow kitty
stow ranger
stow dunst
stow bins
