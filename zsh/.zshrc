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

# oh-my-zsh can put its own directories in front. .zshenv holds the order,
# thus read it again here.
source $HOME/.zshenv

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

alias slop='claude --dangerously-skip-permissions'

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
eval "$(direnv hook zsh)"

# jobstates lets precmd detect a running/suspended background job, so we do not fight a program drawing to terminal
zmodload zsh/parameter 2>/dev/null

# Immediate prompt before starship populates after async
typeset -g _STARSHIP_LOADING=$'\n%B%F{#ff657a}%n%f%b%{\e[3m%}%F{#edc763}@%m%f%{\e[23m%}%F{#ff657a}:%f%B%F{#bad761}%~%f%b\n$ '
typeset -g _STARSHIP_PROMPT=$_STARSHIP_LOADING _STARSHIP_RPROMPT='' _STARSHIP_ASYNC_FD=
PROMPT='$_STARSHIP_PROMPT'
RPROMPT='$_STARSHIP_RPROMPT'

_starship_async_callback() {
  local fd=$1 data
  data="$(command cat <&$fd)"
  zle -F $fd 2>/dev/null
  { exec {fd}<&- } 2>/dev/null
  # unset, not `=`: `exec {var}<` makes var an INTEGER param, so assigning the
  # empty string would silently yield 0 -- and 0 is the terminal's stdin.
  unset _STARSHIP_ASYNC_FD
  if [[ -n $data ]]; then
    local left right
    if [[ $data == *$'\036'* ]]; then
      left=${data%%$'\036'*}
      right=${data#*$'\036'}
    else
      # No separator (should not happen); treat the whole payload as the left
      # prompt and leave RPROMPT empty rather than duplicating it on the right.
      left=$data
      right=''
    fi
    # RPROMPT must stay single-line; a stray newline blanks/garbles the prompt.
    while [[ $left == *$'\n' ]]; do left=${left%$'\n'}; done
    while [[ $right == *$'\n' ]]; do right=${right%$'\n'}; done
    [[ -n $left ]] && _STARSHIP_PROMPT=$left
    _STARSHIP_RPROMPT=$right
  fi
  zle reset-prompt
}

_starship_async_precmd() {
  # `> 2` guard: never close stdin/stdout/stderr, whatever the parameter holds.
  if (( ${_STARSHIP_ASYNC_FD:-0} > 2 )); then
    zle -F $_STARSHIP_ASYNC_FD 2>/dev/null
    { exec {_STARSHIP_ASYNC_FD}<&- } 2>/dev/null
    unset _STARSHIP_ASYNC_FD
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
    printf '\036'
    starship prompt --right --terminal-width="$cols" --keymap="$km" --status="$st" --pipestatus="$ps" --jobs="$jobs" --cmd-duration="$dur" 2>/dev/null
  )
  zle -F $_STARSHIP_ASYNC_FD _starship_async_callback
}

# The process-substitution fd above is NOT close-on-exec, so any program started
# while it is still open (e.g. nvim, before the async callback has fired) would
# inherit it. Close it before every command so nothing inherits it.
_starship_async_cleanup() {
  if (( ${_STARSHIP_ASYNC_FD:-0} > 2 )); then
    zle -F $_STARSHIP_ASYNC_FD 2>/dev/null
    { exec {_STARSHIP_ASYNC_FD}<&- } 2>/dev/null
    unset _STARSHIP_ASYNC_FD
  fi
}
add-zsh-hook precmd _starship_async_precmd
add-zsh-hook preexec _starship_async_cleanup
