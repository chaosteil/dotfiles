#!/bin/bash
set -e

build=$(mktemp -d) || exit 1

pushd "$build"
  # TODO: also investigate pikaur
  git clone https://aur.archlinux.org/yay.git

  pushd "yay"
    makepkg -sri
  popd
popd

rm -rf "$build"
