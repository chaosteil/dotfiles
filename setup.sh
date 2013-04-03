#!/bin/sh
HOME=$HOME
PWD=`pwd`

# git settings

rm $HOME/.gitignore
ln -s $PWD/gitignore $HOME/.gitignore

rm $HOME/.gitconfig
ln -s $PWD/gitconfig $HOME/.gitconfig

# Initialize all submodules

git submodule update --init

# Vim settings
rm $HOME/.vimrc
ln -s $PWD/vimrc $HOME/.vimrc

rm -r $HOME/.vim
ln -s $PWD/vim $HOME/.vim

vim +BundleInstall +qall

# zsh settings
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
rm $HOME/.zshrc
ln -s $PWD/zshrc $HOME/.zshrc
ln -s $PWD/zsh/oh-my-zsh/themes/chaosteil.zsh-theme $HOME/.oh-my-zsh/themes/chaosteil.zsh-theme
