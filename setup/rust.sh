#!/bin/bash

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cargo install \
  cargo-update \
  cargo-edit \
  cargo-audit \
  flamegraph
