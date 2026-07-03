export XDG_CONFIG_HOME=$HOME/.config
export TERM=xterm-256color

ZSH=$HOME/.oh-my-zsh
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

VI_MODE_SET_CURSOR=true
VI_MODE_CURSOR_NORMAL=1
VI_MODE_CURSOR_VISUAL=1

source $ZSH/oh-my-zsh.sh

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH
# Add local bin directories to path
if [ -d "$HOME/.local/bin" ]; then export PATH="$HOME/.local/bin:$PATH"; fi
if [ -d "$HOME/.cargo/bin" ]; then export PATH="$HOME/.cargo/bin:$PATH"; fi
if [ -d "$HOME/bin" ]; then export PATH="$HOME/bin:$PATH"; fi
bindkey -v
KEYTIMEOUT=1  # Shortens ESC key delay

bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Replace with rust equivalents
alias ls='eza --group-directories-first --icons'
alias cat='bat'

# Open the right editor when requested
alias vim='nvim'
alias vi='nvim'
export EDITOR='nvim'

# SSH agent should be available everywhere
export SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-"$XDG_RUNTIME_DIR/ssh-agent.socket"}

# Hilarious!
if type thefuck &> /dev/null; then
  eval "$(thefuck --alias)"
fi

for ft in go rs; do
  alias -s "$ft"="$EDITOR"
done

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

# jobstates lets precmd detect a running/suspended background job, so we do not fight a program drawing to terminal
zmodload zsh/parameter 2>/dev/null

# Immediate prompt before starship populates after async
typeset -g _STARSHIP_LOADING=$'\n%B%F{#ff657a}%n%f%b%{\e[3m%}%F{#edc763}@djmbp4%f%{\e[23m%}%F{#ff657a}:%f%B%F{#bad761}%~%f%b\n$ '
typeset -g _STARSHIP_PROMPT=$_STARSHIP_LOADING _STARSHIP_RPROMPT='' _STARSHIP_ASYNC_FC=
PROMPT='$_STARSHIP_PROMPT'
RPROMPT='$_STARSHIP_RPROMPT'

_starship_async_callback() {
  local fd=$1 data
  data="$(command cat <&$fd)"
  zle -F $fd 2>/dev/null
  { exec {fd}<&- } 2>/dev/null
  _STARSHIP_ASYNC_FD=
  if [[ -n $data ]]; then
    local left=${data%%$'\036'*}
    while [[ $left == *$'\n' ]]; do left=${left%$'\n'}; done
    _STARSHIP_PROMPT=$left
    _STARSHIP_RPROMPT=${data#*$'\036'}
  fi
  zle reset-prompt
}

_starship_async_precmd() {
  if [[ -n $_STARSHIP_ASYNC_FD ]]; then
    zle -F $_STARSHIP_ASYNC_FD 2>/dev/null
    { exec {_STARSHIP_ASYNC_FD}<&- } 2>/dev/null
      _STARSHIP_ASYNC_FD=
  fi
  local cols=$COLUMNS km=${KEYMAP:-} st=${STARSHIP_CMD_STATUS:-0}
  local ps="${STARSHIP_PIPE_STATUS[*]:-}" dur=${STARSHIP_DURATION:-0} jobs=${STARSHIP_JOBS_COUNT:-0}
  # Async fix due to backgrounded jobs
  if (( ${#jobstates} )); then
    _STARSHIP_PROMPT="$(starship prompt --terminal-width="$cols" --keymap="$km" --status="$st" --pipestatus="$ps" --jobs="$jobs" --cmd-duration="$dur" 2>/dev/null)"
    _STARSHIP_RPROMPT="$(starship prompt --right --terminal-width="$cols" --keymap="$km" --status="$st" --pipestatus="$ps" --jobs="$jobs" --cmd-duration="$dur" 2>/dev/null)"
    return
  fi
  # Prepare regular callback
  _STARSHIP_PROMPT=$_STARSHIP_LOADING _STARSHIP_RPROMPT=''
  exec {_STARSHIP_ASYNC_FD}< <(
    starship prompt --terminal-width="$cols" --keymap="$km" --status="$st" --pipestatus="$ps" --jobs="$jobs" --cmd-duration="$dur" 2>/dev/null
    starship prompt --right --terminal-width="$cols" --keymap="$km" --status="$st" --pipestatus="$ps" --jobs="$jobs" --cmd-duration="$dur" 2>/dev/null
  )
  zle -F $_STARSHIP_ASYNC_FD _starship_async_callback
}
add-zsh-hook precmd _starship_async_precmd
