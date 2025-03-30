#!/bin/bash

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --diagnostic-endpoint="" --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

nix run nixpkgs#git -- clone --bare https://github.com/rob-3/dotfiles "$HOME/.dotfiles"
nix run nixpkgs#git -- --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" switch phone
nix run nixpkgs#git -- --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" checkout

cd "$HOME/.config/nix" || exit
nix profile install
