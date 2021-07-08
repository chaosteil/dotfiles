# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="chaosteil"
export TERM=xterm-256color

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# This breaks zsh autosuggest, so we disable it
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(colorize adb ant git colored-man-pages golang python safe-paste dircycle docker encode64 jira vi-mode zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=$PREFIXPATH:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/local/git/bin:$PATH
export PATH="$HOME/bin:$PATH" # A local bin dir in home!
bindkey -v

bindkey '^[[A' up-line-or-search                                                
bindkey '^[[B' down-line-or-search

# Replace with rust equivalents
alias ls='exa'
alias cat='bat'

# Open the right editor when requested ;)
alias vim='nvim'
alias vi='nvim'
export EDITOR='nvim'

# SSH agent should be available everywhere
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Hilarious!
eval $(thefuck --alias)

alias -s txt=$EDITOR
alias -s cpp=$EDITOR
alias -s c=$EDITOR
alias -s h=$EDITOR
alias -s lua=$EDITOR
alias -s go=$EDITOR
alias -s rs=$EDITOR
alias todo="$EDITOR ~/notes/TODO.md"
alias nn="$EDITOR ~/notes/"

# Show long performing commands after 10 seconds
REPORTTIME=10

source ~/.local_paths
