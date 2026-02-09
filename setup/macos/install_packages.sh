#!/bin/bash

# some of those tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

brew install \
  atuin \
  bat \
  ctags \
  cmake \
  cowsay \
  deskpad \
  eza \
  fd \
  ffmpeg \
  gh \
  ghostty \
  git-delta \
  go \
  gopls \
  htop \
  jj \
  jjui \
  jq \
  kitty \
  kubectl \
  markdownlint-cli \
  nodejs \
  rar \
  ripgrep \
  rust-analyzer \
  shellcheck \
  stow \
  thefuck \
  tig \
  tmux \
  watchman \
  yarn \
  zoxide

brew install --HEAD neovim
sudo pip3 install neovim

brew install --cask nikitabobko/tap/aerospace
brew tap FelixKratz/formulae
brew install borders

npm install -g typescript typescript-language-server eslint prettier

# Delete the configs by doing `defaults delete -g NAME`

# Set date format in menu bar
defaults write com.apple.menuextra.clock DateFormat -string 'EEE MMM d  H:mm:ss'
# Make png default for screenshots
defaults write com.apple.screencapture type -string png
# Always show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show column view in finder by default
defaults write com.apple.finder FXPreferredViewStyle -string clmv
# Show ~/Library by default
chflags nohidden ~/Library
# Show /Volumes
sudo chflags nohidden /Volumes
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -int 1
# Show full filepath in finder windows
defaults write _FXShowPosixPathInTitle com.apple.finder -int 1
# No DS_Store in network shares
defaults write DSDontWriteNetworkStores com.apple.desktopservices -int 1
# Command + Control + Click to move windows by clicking on any part of it
defaults write -g NSWindowShouldDragOnGesture -bool true
