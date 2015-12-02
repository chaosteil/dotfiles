#!/bin/sh
HOME=$HOME
PWD=`pwd`
CONFIG=$HOME/.config

mkdir -p $HOME/.config

# git settings

rm $HOME/.gitignore
ln -s $PWD/gitignore $HOME/.gitignore

rm $HOME/.gitconfig
ln -s $PWD/gitconfig $HOME/.gitconfig

# Initialize all submodules

git submodule update --init --recursive

# Neovim settings
rm -r $CONFIG/nvim
ln -s $PWD/nvim $CONFIG/nvim

nvim +PlugInstall +qall

# zsh settings
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
rm $HOME/.zshrc
ln -s $PWD/zshrc $HOME/.zshrc
ln -s $PWD/zsh/oh-my-zsh/themes/chaosteil.zsh-theme $HOME/.oh-my-zsh/themes/chaosteil.zsh-theme
ln -s $PWD/zsh/oh-my-zsh/custom/plugins/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
ln -s $PWD/zsh/oh-my-zsh/custom/plugins/zsh-syntax-highlighting $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
touch $HOME/.local_paths

# terminal settings
rm -r $CONFIG/i3
ln -s $PWD/i3 $CONFIG/i3
rm -r $CONFIG/terminator
ln -s $PWD/terminator $CONFIG/terminator
