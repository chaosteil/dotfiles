export XDG_CONFIG_HOME=$HOME/.config

ZSH=$HOME/.oh-my-zsh

export TERM=xterm-256color

plugins=(
  colored-man-pages
  colorize
  encode64
  macos
  safe-paste
  vi-mode
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

export PATH=$PREFIXPATH:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/local/git/bin:$PATH
# Add local bin directories to path
if [ -d "$HOME/.local/bin" ]; then export PATH="$HOME/.local/bin:$PATH"; fi
if [ -d "$HOME/.cargo/bin" ]; then export PATH="$HOME/.cargo/bin:$PATH"; fi
if [ -d "$HOME/bin" ]; then export PATH="$HOME/bin:$PATH"; fi
bindkey -v

bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Replace with rust equivalents
alias ls='eza --group-directories-first --icons'
alias cat='bat'

# Open the right editor when requested ;)
alias vim='nvim'
alias vi='nvim'
export EDITOR='nvim'

# JJ config file
export JJ_CONFIG="$HOME/.config/jj/config.toml"

# SSH agent should be available everywhere
export SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-"$XDG_RUNTIME_DIR/ssh-agent.socket"}

# Hilarious!
if type thefuck &> /dev/null; then
  eval "$(thefuck --alias)"
fi

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

# Force tools to display 24 bits of color
if [[ -n "$TMUX" ]] && [[ -z "$COLORTERM" ]]; then
  export COLORTERM=truecolor
fi

if [ -f "$HOME/.local_paths" ]; then
  source "$HOME/.local_paths"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(zoxide init zsh)"
alias cd='z'
eval "$(atuin init zsh)"
eval "$(starship init zsh)"
