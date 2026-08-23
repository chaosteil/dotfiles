# nix has no fish integration here; source it for its env vars.
set -l nix_profile /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
test -r $nix_profile; and source $nix_profile

# $fish_user_paths is sticky, and a global one never reaches $PATH on fish 4.8.
set -q -U fish_user_paths; and set -e -U fish_user_paths
set -q -g fish_user_paths; and set -e -g fish_user_paths

# --move makes this idempotent: a re-source always gives this order.
fish_add_path --path --move --prepend \
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
