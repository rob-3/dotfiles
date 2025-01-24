#!/bin/bash

dnf install git -y

git clone --bare https://github.com/rob-3/dotfiles "$HOME/.dotfiles"
git checkout --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --diagnostic-endpoint="" --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

cd "$HOME/.config/nix" || exit
nix profile install
