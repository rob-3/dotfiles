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
setopt HIST_IGNORE_ALL_DUPS
bindkey -v
# End of lines configured by zsh-newuser-install

setopt histignorespace

autoload -Uz promptinit
promptinit
export PURE_GIT_PULL=0
# Completion for kitty
#kitty + complete setup zsh | source /dev/stdin
prompt pure
zstyle :prompt:pure:git:stash show yes

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey ' ' magic-space

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^ ' autosuggest-execute
bindkey '^l' autosuggest-accept
#bindkey '^[[[CE' autosuggest-execute
bindkey '^j' history-substring-search-down
bindkey '^k' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey '^p' history-substring-search-up

alias g++='g++ -pedantic-errors -Wall -Weffc++ -Wextra -Wsign-conversion -Werror'
alias vimrc="nvim ~/.config/nvim/lua/rob-3/init.lua"
alias ssh="kitty +kitten ssh"
alias vim=:
alias vimdiff="nvim -d"
alias rgf="rg --files"
export GPG_TTY=$(tty)
# theming
#source .theme.sh
#alias dark="cp ~/.config/kitty/kitty-themes/themes/Solarized_Dark.conf ~/.config/kitty/kitty-themes/themes/current.conf && cp ~/.dark.sh ~/.theme.sh"
#alias light="cp ~/.config/kitty/kitty-themes/themes/Solarized_Light.conf ~/.config/kitty/kitty-themes/themes/current.conf && cp ~/.light.sh ~/.theme.sh"
alias dark="kitty +kitten themes --reload-in=all Solarized\ Dark && echo \"export THEME=0\" > ~/.theme.sh && export THEME=0"
alias light="kitty +kitten themes --reload-in=all Solarized\ Light && echo \"export THEME=1\" > ~/.theme.sh && export THEME=1"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
gpg-connect-agent /bye

alias icat="kitty +kitten icat"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

#function cssetup() {
#	infocmp -a xterm-kitty | gh cs ssh -c "$1" -- tic -x -o ~/.terminfo /dev/stdin
#}

eval "$(fnm env --use-on-cd)"

#export PATH="/Users/rob/git/bin-wrappers:$PATH"
export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"

setopt share_history

export PATH="/Users/rob/.ghcup/ghc/8.10.7/bin:$PATH"
export PATH="/opt/homebrew/opt/gnu-units/libexec/gnubin:$PATH"
export FZF_DEFAULT_COMMAND='fd -H --type f'
export FZF_CTRL_T_COMMAND='fd -H --type f'
export FZF_ALT_C_COMMAND='fd -H --type d'

export JAVA_HOME=/opt/homebrew/Cellar/openjdk/20/libexec/openjdk.jdk/Contents/Home

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#source ~/.config/wezterm/wezterm.sh

export EDITOR=nvim

# bun completions
#[ -s "/Users/rob/.bun/_bun" ] && source "/Users/rob/.bun/_bun"

# bun
#export BUN_INSTALL="$HOME/.bun"
#export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

zle-line-init() {
echo -ne "\e[2 q"
}

zle -N zle-line-init

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''

#export TERM=xterm-256color
