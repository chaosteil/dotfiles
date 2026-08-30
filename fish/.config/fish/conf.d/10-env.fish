set -gx XDG_CONFIG_HOME $HOME/.config
set -gx EDITOR nvim
set -gx VISUAL nvim

# 24-bit color for tools that only read COLORTERM.
if set -q TMUX; and not set -q COLORTERM
    set -gx COLORTERM truecolor
end

# Colorize man pages
set -gx MANROFFOPT -c
set -gx MANPAGER 'sh -c "col -bx | bat --language man --style plain"'

for dir in /etc/profiles/per-user/$USER $HOME/.nix-profile
    set -l vars $dir/etc/profile.d/hm-session-vars.fish
    if test -r $vars
        source $vars
        break
    end
end
