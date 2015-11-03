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
 COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(zsh-syntax-highlighting colorize adb ant git brew brew-cask colored-man python safe-paste dircycle docker encode64 jira nyan osx vi-mode)

source $ZSH/oh-my-zsh.sh
source ~/.local_paths

# Customize to your needs...
export PATH=$PREFIXPATH:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/local/git/bin:$PATH
bindkey -v

bindkey '^[[A' up-line-or-search                                                
bindkey '^[[B' down-line-or-search

# colored completion - use my LS_COLORS
#zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

alias irssi='TERM=screen-256color irssi'
alias weechat='TERM=screen-256color weechat'
alias ls='ls -Gh --color'

export EDITOR='nvim'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Hilarious!
eval $(thefuck --alias)

# transfer.sh
transfer() { if [ $# -eq 0 ]; then echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi 
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; }; alias transfer=transfer 
