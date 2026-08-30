set -l nix_profile /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
test -r $nix_profile; and source $nix_profile

set -q -U fish_user_paths; and set -e -U fish_user_paths
set -q -g fish_user_paths; and set -e -g fish_user_paths

# --move makes this idempotent: a re-source always gives this order.
fish_add_path --path --move --prepend \
    /etc/profiles/per-user/$USER/bin \
    /run/current-system/sw/bin \
    $HOME/.nix-profile/bin \
    /opt/homebrew/bin \
    $HOME/Library/Python/3.9/bin \
    $HOME/bin \
    $HOME/.cargo/bin \
    $HOME/.local/bin \
    /usr/local/bin /usr/bin /bin /usr/sbin /sbin \
    /nix/var/nix/profiles/default/bin

fish_add_path --path --move --append \
    /opt/homebrew/sbin \
    $HOME/go/bin \
    $HOME/.linkerd2/bin

direnv hook fish | source
