#!/usr/bin/env bash
build=`mktemp -d` || exit 1

pushd "$build"
  git clone https://aur.archlinux.org/cower.git
  git clone https://aur.archlinux.org/pacaur.git

  pushd "cower"
    makepkg -sri --skippgpcheck
  popd

  pushd "pacaur"
    makepkg -sri
  popd
popd

rm -rf "$build"
