#!/bin/bash

yay -Syu "$(cat pacman_deps.txt)" "$(cat aur_deps.txt)"
