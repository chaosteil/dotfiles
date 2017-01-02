#!/usr/bin/env bash

# git
stow git
git submodule update --init --recursive

# nvim
stow nvim
nvim +PlugInstall +qall

# zsh
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
touch "$HOME/.local_paths"
stow zsh

stow i3
stow termite
stow ranger
stow dunst
stow bins
