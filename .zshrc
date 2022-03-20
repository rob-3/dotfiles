# The following lines were added by compinstall
#zmodload zsh/zprof
#zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'l:|=* r:|=*'
#zstyle ':completion:*' max-errors 1 numeric
zstyle :compinstall filename '/home/daystrom/.zshrc'

#fpath=(~/.zsh $fpath)
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

setopt histignorespace

autoload -Uz promptinit
promptinit
# Completion for kitty
kitty + complete setup zsh | source /dev/stdin
prompt pure
zstyle :prompt:pure:git:stash show yes

source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/autojump/autojump.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

bindkey ' ' magic-space

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^ ' autosuggest-accept
bindkey '^l' autosuggest-accept
bindkey '^j' history-substring-search-down
bindkey '^k' history-substring-search-up

alias g++='g++ -pedantic-errors -Wall -Weffc++ -Wextra -Wsign-conversion -Werror'
alias vimrc="vim ~/.config/nvim/init.vim"
alias ssh="kitty +kitten ssh"
alias vim=nvim
alias vimdiff="nvim -d"
export GPG_TTY=$(tty)
# theming
export THEME=0
alias dark="kitty @ set-colors -a "~/.config/kitty/kitty-themes/themes/Solarized_Dark.conf" && export THEME=0"
alias light="kitty @ set-colors -a "~/.config/kitty/kitty-themes/themes/Solarized_Light.conf" && export THEME=1"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent /bye

alias icat="kitty +kitten icat"
