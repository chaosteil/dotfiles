#!/usr/bin/env bash

home=$HOME
cwd=`pwd`
config=$HOME/.config

mkdir -p $config

# git settings

rm $home/.gitignore
ln -s $cwd/gitignore $home/.gitignore

rm $home/.gitconfig
ln -s $cwd/gitconfig $home/.gitconfig

# Initialize all submodules

git submodule update --init --recursive

# Neovim settings
rm -r $config/nvim
ln -s $cwd/nvim $config/nvim

nvim +PlugInstall +qall

# zsh settings
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
rm $home/.zshrc
ln -s $cwd/zshrc $home/.zshrc
ln -s $cwd/zsh/oh-my-zsh/themes/chaosteil.zsh-theme $home/.oh-my-zsh/themes/chaosteil.zsh-theme
ln -s $cwd/zsh/oh-my-zsh/custom/plugins/zsh-autosuggestions $home/.oh-my-zsh/custom/plugins/zsh-autosuggestions
ln -s $cwd/zsh/oh-my-zsh/custom/plugins/zsh-syntax-highlighting $home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
touch $home/.local_paths

# terminal/desktop settings
rm -r $config/i3
ln -s $cwd/i3 $config/i3
rm -r $config/terminator
rm -r $config/ranger
ln -s $cwd/ranger $config/ranger
ln -s $cwd/terminator $config/terminator
ln -s $cwd/dunst $config/dunst
ln -s $cwd/Xresources $home/.Xresources
ln -s $cwd/xinitrc $home/.xinitrc
