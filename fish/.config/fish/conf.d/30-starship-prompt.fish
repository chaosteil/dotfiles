# Async starship: a synchronous prompt stalls on starship-jj in a large repo.

if status is-interactive
    set -g __starship_cache (command mktemp -d)
    set -g __starship_generation 0

    set -gx STARSHIP_SHELL fish
    set -gx STARSHIP_SESSION_KEY (random 10000000000000 9999999999999999)
    # starship draws the venv and the vi mode itself.
    set -g VIRTUAL_ENV_DISABLE_PROMPT 1
    functions --erase fish_mode_prompt

    function fish_prompt
        __starship_cached left
    end

    function fish_right_prompt
        __starship_cached right
    end

    function __starship_cached --argument-names side
        set -l cache $__starship_cache/$side
        test -e $cache; and string collect <$cache
    end

    # Kept out of __starship_render so the hop below can pass it on as a single
    # `fish -c` argument.
    set -g __starship_worker '
        set -l cache $argv[1]
        set -l generation $argv[2]
        set -l shell $argv[3]
        set -l args $argv[4..]

        starship prompt $args >$cache/$generation.left
        starship prompt --right $args >$cache/$generation.right

        # A missing cache means the shell is gone and cleaned up after itself;
        # `test` fails on the empty string, so the signal is never sent to a
        # pid that has since been recycled.
        if test $generation = (cat $cache/generation 2>/dev/null)
            # Rename inside one directory, so no redraw reads a partial cache.
            mv -f $cache/$generation.left $cache/left
            mv -f $cache/$generation.right $cache/right
            kill -s USR1 $shell
        else
            rm -f $cache/$generation.left $cache/$generation.right
        end
    '

    # Shown from each prompt until that prompt's render lands.
    function __starship_placeholder
        echo -n \n(set_color -o ff657a)$USER(set_color normal)
        echo -n (set_color -i edc763)@(prompt_hostname)(set_color normal)
        echo -n (set_color ff657a):(set_color normal)
        # --dir-length=0 keeps the whole path, like the zsh %~.
        echo -n (set_color -o bad761)(prompt_pwd --dir-length=0)(set_color normal)\n'$ '
    end

    function __starship_render --on-event fish_prompt
        # Capture first: only `set` leaves $status and $pipestatus intact.
        set -l cmd_status $status
        set -l cmd_pipestatus $pipestatus
        set -l duration 0
        set -q CMD_DURATION; and set duration $CMD_DURATION

        set -l keymap insert
        if contains -- $fish_key_bindings fish_vi_key_bindings fish_hybrid_key_bindings
            set keymap $fish_bind_mode
        end

        # A render drops its output when a newer prompt has bumped this stamp.
        set -g __starship_generation (math $__starship_generation + 1)
        echo $__starship_generation >$__starship_cache/generation

        # Reset to the placeholder on every prompt, not just the first one:
        # leaving the last render up means the directory, the status and the
        # branch on screen are the ones from before the command that just ran,
        # and the slower starship is the longer that lie stays up. Blank the
        # right side too -- the placeholder has no counterpart for it.
        __starship_placeholder >$__starship_cache/left
        echo -n >$__starship_cache/right

        # Two hops, because the render must be neither a job nor a child of
        # this shell: `disown` drops it from the list fish reaps -- fish only
        # polls disowned pids while some other job is alive -- so each prompt
        # would leave a zombie for the life of the shell, and a plain `&` reaps
        # but shows the render in `jobs` and makes `exit` ask twice. The first
        # hop backgrounds the second and exits for the shell to reap; init
        # adopts the render. It has to be a command, as fish waits for a
        # backgrounded `begin` block of its own.
        #
        # /dev/null throughout: a wedged render outlives the shell, and a
        # single inherited fd keeps the terminal's pty device allocated.
        command fish --no-config -c \
            'command fish --no-config -c $argv </dev/null >/dev/null 2>/dev/null &' \
            $__starship_worker $__starship_cache $__starship_generation $fish_pid \
            --terminal-width=$COLUMNS --status=$cmd_status \
            --pipestatus="$cmd_pipestatus" --keymap=$keymap \
            --cmd-duration=$duration --jobs=(jobs --group 2>/dev/null | count) &
    end

    function __starship_repaint --on-signal SIGUSR1
        commandline --function repaint
    end

    function __starship_cleanup --on-event fish_exit
        command rm -rf $__starship_cache
    end
end
