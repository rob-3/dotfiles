#!/bin/bash

dnf install git -y

git clone --bare https://github.com/rob-3/dotfiles "$HOME/.dotfiles"
git checkout --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"
