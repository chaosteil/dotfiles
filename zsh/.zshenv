# Every zsh reads this file, thus it holds the environment that a
# non-interactive shell also needs. The interactive settings are in .zshrc.
#
# It is the zsh copy of fish/.config/fish/conf.d/10-env.fish, 20-path.fish and
# 50-secretive.fish. A tool that starts zsh instead of fish gets the same PATH.

export XDG_CONFIG_HOME=$HOME/.config
export EDITOR=nvim
export VISUAL=nvim

# Colorize man pages.
export MANROFFOPT=-c
export MANPAGER='sh -c "col -bx | bat --language man --style plain"'

# The session variables of home-manager.
for _hm_dir in /etc/profiles/per-user/$USER $HOME/.nix-profile; do
  _hm_vars=$_hm_dir/etc/profile.d/hm-session-vars.sh
  if [[ -r $_hm_vars ]]; then
    source $_hm_vars
    break
  fi
done
unset _hm_dir _hm_vars

_nix_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [[ -r $_nix_profile ]]; then
  source $_nix_profile
fi
unset _nix_profile

# `typeset -U` keeps the first copy of a duplicate. A directory that $path
# already holds thus moves to the front, and a re-source gives this same order.
typeset -U path PATH
path=(
  /etc/profiles/per-user/$USER/bin
  /run/current-system/sw/bin
  $HOME/.nix-profile/bin
  /opt/homebrew/bin
  $HOME/Library/Python/3.9/bin
  $HOME/bin
  $HOME/.cargo/bin
  $HOME/.local/bin
  /usr/local/bin /usr/bin /bin /usr/sbin /sbin
  /nix/var/nix/profiles/default/bin
  $path
)

# The same rule holds these back: remove them first, or the earlier copy wins.
_path_tail=(
  /opt/homebrew/sbin
  $HOME/go/bin
  $HOME/.linkerd2/bin
)
path=(${path:|_path_tail} $_path_tail)
unset _path_tail

# The SSH agent of Secretive, when it runs.
if [[ $(uname) == Darwin ]]; then
  _secretive=$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
  if [[ -S $_secretive ]]; then
    export SSH_AUTH_SOCK=$_secretive
  fi
  unset _secretive
fi
