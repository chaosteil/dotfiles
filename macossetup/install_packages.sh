#!/bin/bash

# some of those tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

brew install \
  bat \
  exa \
  go \
  gopls \
  jq \
  kitty \
  kubectl \
  markdownlint-cli \
  nodejs \
  ripgrep \
  rust-analyzer \
  shellcheck \
  stow \
  thefuck \
  tig \
  yarn
brew install --HEAD neovim
sudo pip3 install neovim
cargo install \
  cargo-update \
  cargo-edit \
  cargo-audit

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
