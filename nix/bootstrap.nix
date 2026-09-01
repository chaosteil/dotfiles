# One command to set up a new machine. The header of flake.nix shows
# the usage.
{
  pkgs,
  home-manager,
  darwin-rebuild ? null,
}:
pkgs.writeShellApplication {
  name = "bootstrap";
  runtimeInputs = [
    pkgs.jujutsu
    pkgs.git
  ];
  text = ''
    repo="$HOME/dotfiles"
    flake="$repo/nix"
    user="$USER"

    mode=""
    dry=0
    for arg in "$@"; do
      case "$arg" in
        --darwin) mode=darwin ;;
        --standalone) mode=home ;;
        --dry-run) dry=1 ;;
        *)
          echo "usage: bootstrap [--darwin | --standalone] [--dry-run]" >&2
          exit 1
          ;;
      esac
    done

    # Get the repository as a colocated jujutsu repository.
    if [ ! -d "$repo" ]; then
      jj git clone --colocate https://github.com/chaosteil/dotfiles.git "$repo"
      git -C "$repo" submodule update --init
    elif [ ! -d "$repo/.jj" ]; then
      jj git init --colocate "$repo"
    fi

    if [ ! -d "$flake" ]; then
      echo "$repo has no nix flake: update the repository first" >&2
      exit 1
    fi

    arch="$(uname -m)"
    if [ "$arch" = arm64 ]; then
      arch=aarch64
    fi
    if [ "$(uname -s)" = Darwin ]; then
      host="$(/usr/sbin/scutil --get LocalHostName)"
      platform=darwin
    else
      host="$(uname -n)"
      host="''${host%%.*}"
      platform=linux
    fi

    # Write a host file for an unknown machine.
    hostfile="$flake/hosts/$host.nix"
    if [ ! -f "$hostfile" ]; then
      mkdir -p "$flake/hosts"
      printf '{\n  system = "%s-%s";\n  user = "%s";\n}\n' \
        "$arch" "$platform" "$user" > "$hostfile"
      if [ "$dry" = 1 ]; then
        jj -R "$repo" status > /dev/null
        echo "dry run: $hostfile stays uncommitted" >&2
      else
        if ! jj -R "$repo" config get user.name > /dev/null 2>&1; then
          # A fresh machine has no jj identity yet.
          export JJ_USER="$user"
          export JJ_EMAIL="$user@$host"
        fi
        (
          cd "$repo" || exit 1
          jj commit -m "feat(nix): Add host $host" "nix/hosts/$host.nix"
        )
      fi
    fi
  ''
  + pkgs.lib.optionalString (darwin-rebuild != null) ''

    # On macOS, ask which of the two configuration types to apply.
    if [ -z "$mode" ]; then
      if [ ! -t 0 ]; then
        echo "no terminal: give --darwin or --standalone" >&2
        exit 1
      fi
      printf 'Apply [1] nix-darwin (full system) or [2] home-manager (user only)? [1/2] '
      read -r answer
      case "$answer" in
        1) mode=darwin ;;
        2) mode=home ;;
        *)
          echo "answer 1 or 2" >&2
          exit 1
          ;;
      esac
    fi
    if [ "$mode" = darwin ]; then
      if [ "$dry" = 1 ]; then
        # A dry run does not commit the host file. The "path:" prefix makes
        # nix read the directory as it is, so the new file is visible.
        ${darwin-rebuild}/bin/darwin-rebuild build --flake "path:$flake"
      else
        sudo ${darwin-rebuild}/bin/darwin-rebuild switch --flake "$flake"
      fi
      exit 0
    fi
  ''
  + ''

    if [ "$mode" = darwin ]; then
      echo "nix-darwin needs macOS" >&2
      exit 1
    fi
    if [ "$dry" = 1 ]; then
      # See the note above on the "path:" prefix.
      ${home-manager}/bin/home-manager build --flake "path:$flake"
    else
      ${home-manager}/bin/home-manager switch --flake "$flake" -b hm-bak
    fi
  '';
}
