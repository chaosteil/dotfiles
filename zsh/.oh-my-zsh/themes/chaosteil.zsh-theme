# Colors based on Steve Losh's Prose theme, with some modifications I don't remember, srs

local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

function collapse_pwd {
    echo $(pwd | sed -e "s,^$HOME,~,")
}

function prompt_char {
    git branch >/dev/null 2>/dev/null && echo "%{$fg[yellow]%}±%{$reset_color%}" && return
    echo '$'
}

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

function hg_prompt_info {
    hg prompt --angle-brackets "\
< on %{$fg[magenta]%}<branch>%{$reset_color%}>\
< at %{$fg[yellow]%}<tags|%{$reset_color%}, %{$fg[yellow]%}>%{$reset_color%}>\
%{$fg[green]%}<status|modified|unknown><update>%{$reset_color%}<
patches: <patches|join( → )|pre_applied(%{$fg[yellow]%})|post_applied(%{$reset_color%})|pre_unapplied(%{$fg_bold[black]%})|post_unapplied(%{$reset_color%})>>" 2>/dev/null
}

PROMPT='
%{$fg[red]%}%n%{$reset_color%}@%{$fg[yellow]%}%m%{$reset_color%}:%{$fg_bold[green]%}$(collapse_pwd)%{$reset_color%}$(git_prompt_info)
$(virtualenv_info)$(prompt_char) '

ZSH_THEME_GIT_PROMPT_PREFIX=" | %{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} +"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[green]%}⚡"
ZSH_THEME_GIT_PROMPT_UNTRACKED=" %{$fg[green]%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""

RPS1="${return_code}"
