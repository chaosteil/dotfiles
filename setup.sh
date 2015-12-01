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
rm -r $PWD/zsh/oh-my-zsh/custom/plugins
ln -s $PWD/zsh/oh-my-zsh/custom/plugins $HOME/.oh-my-zsh/custom/plugins
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
touch $HOME/.local_paths

# terminal settings
rm -r $CONFIG/i3
ln -s $PWD/i3/config $CONFIG/i3/config
rm -r $CONFIG/terminator
ln -s $PWD/terminator/config $CONFIG/terminator/config
