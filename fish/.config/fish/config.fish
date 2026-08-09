if status is-interactive
    set -g fish_greeting
    set -g fish_key_bindings fish_vi_key_bindings
    set -g fish_escape_delay_ms 10

    # VI_MODE_CURSOR_NORMAL=1 and VI_MODE_CURSOR_VISUAL=1 were a blinking block.
    set -g fish_cursor_default block blink
    set -g fish_cursor_visual block blink
    set -g fish_cursor_insert line
    set -g fish_cursor_replace_one underscore
    fish_vi_cursor

    # fzf first, atuin second: both bind ctrl-r and the last binding wins.
    fzf --fish | source
    atuin init fish | source
    # atuin binds `?` to its LLM prompt.
    bind --erase '?'

    # --cmd cd replaces `alias cd=z`, which zoxide rejects as a loop.
    zoxide init fish --cmd cd | source

    # alias, not functions/: an autoloaded `cat` would also hit scripts.
    alias ls 'eza --group-directories-first --icons'
    alias cat bat
    alias vim nvim
    alias vi nvim
    alias slop 'claude --dangerously-skip-permissions'

    # bash !! and !$. fish rejects a bare $, so the last argument is !. instead.
    function __last_history_item
        echo $history[1]
    end
    function __last_history_token
        # Quoted, or an empty history makes `string split` read the terminal.
        echo (string split ' ' -- "$history[1]")[-1]
    end
    abbr -a '!!' --position anywhere --function __last_history_item
    abbr -a '!.' --position anywhere --function __last_history_token

    # Replaces REPORTTIME=10.
    function __report_slow_command --on-event fish_postexec
        if test $CMD_DURATION -ge 10000
            printf '%s%s took %ss%s\n' (set_color brblack) \
                (string shorten --max 50 -- $argv[1]) \
                (math --scale=1 $CMD_DURATION / 1000) (set_color normal)
        end
    end
end
