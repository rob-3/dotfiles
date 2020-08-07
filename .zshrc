# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'l:|=* r:|=*'
zstyle ':completion:*' max-errors 1 numeric
zstyle :compinstall filename '/home/daystrom/.zshrc'

autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=9999
SAVEHIST=9999
setopt appendhistory autocd notify
bindkey -v
# End of lines configured by zsh-newuser-install

alias ls='ls --color=auto'
alias git=hub
setopt histignorespace

export EDITOR="/usr/bin/nvim"
export VISUAL="$EDITOR"

export GIT_EDITOR="$EDITOR"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export GTK_THEME=breeze-dark
#export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORMTHEME=qt5ct

autoload -Uz promptinit
promptinit
# Completion for kitty
kitty + complete setup zsh | source /dev/stdin
prompt pure

source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/autojump/autojump.zsh

bindkey ' ' magic-space

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^ ' autosuggest-accept
bindkey '^l' autosuggest-accept
bindkey '^j' history-substring-search-down
bindkey '^k' history-substring-search-up

alias g++='g++ -pedantic-errors -Wall -Weffc++ -Wextra -Wsign-conversion -Werror'

XDG_DESKTOP_DIR="$HOME/"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
alias vimrc="vim ~/.config/nvim/init.vim"

alias lock="swaylock -i ~/stuff/lock.png -u"
alias ssh="kitty +kitten ssh"
