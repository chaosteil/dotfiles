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

# Neovim settings
rm -r $HOME/.config/nvim
mkdir -p $HOME/.config
ln -s $PWD/nvim $HOME/.config/nvim

nvim +PlugInstall +qall

# zsh settings
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
rm $HOME/.zshrc
ln -s $PWD/zshrc $HOME/.zshrc
ln -s $PWD/zsh/oh-my-zsh/themes/chaosteil.zsh-theme $HOME/.oh-my-zsh/themes/chaosteil.zsh-theme
ln -s $PWD/zsh/oh-my-zsh/custom/plugins $HOME/.oh-my-zsh/custom/plugins
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
touch $HOME/.local_paths
