#!/usr/bin/env sh
build=`mktemp -d` || exit 1

pushd "$build"
  git clone https://aur.archlinux.org/package-query.git
  git clone https://aur.archlinux.org/yaourt.git

  pushd "package-query"
    makepkg -sri
  popd

  pushd "yaourt"
    makepkg -sri
  popd
popd

rm -rf "$build"
