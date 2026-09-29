# One command to configure a machine. The command also adopts a dotfiles
# checkout that is on the machine already. The header of flake.nix shows
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

    dry=0
    for arg in "$@"; do
      case "$arg" in
        --dry-run) dry=1 ;;
        *)
          echo "usage: bootstrap [--dry-run]" >&2
          exit 1
          ;;
      esac
    done

    # Get the repository as a colocated jujutsu repository.
    if [ ! -d "$repo" ]; then
      jj git clone --colocate https://github.com/chaosteil/dotfiles.git "$repo"
    elif [ ! -e "$repo/.git" ]; then
      echo "$repo is not a git checkout of the dotfiles" >&2
      echo "move the directory away" >&2
      echo "then run this command again" >&2
      exit 1
    elif [ ! -d "$repo/.jj" ]; then
      # A plain checkout becomes colocated. git keeps the same commits,
      # but jj moves git to a detached HEAD. This is normal.
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
        echo "dry run: $hostfile stays uncommitted" >&2
      else
        (
          cd "$repo" || exit 1
          jj commit -m "feat(nix): Add host $host" "nix/hosts/$host.nix"
        )
      fi
    fi

    # A snapshot puts new and changed files into the git index. nix reads
    # the flake through git. It finds the files only after this step.
    jj -R "$repo" status > /dev/null
  ''
  # macOS applies nix-darwin. Linux applies home-manager.
  + (
    if darwin-rebuild != null then
      ''

        if [ "$dry" = 1 ]; then
          # A dry run does not commit the host file. The "path:" prefix makes
          # nix read the directory as it is, so the new file is visible.
          # darwin-rebuild has no flag to skip the result link. A temporary
          # directory keeps the link out of the repository.
          (
            tmp="$(mktemp -d)"
            trap 'rm -rf "$tmp"' EXIT
            cd "$tmp" || exit 1
            ${darwin-rebuild}/bin/darwin-rebuild build --flake "path:$flake"
          )
        else
          sudo ${darwin-rebuild}/bin/darwin-rebuild switch --flake "$flake"
        fi
      ''
    else
      ''

        if [ "$dry" = 1 ]; then
          # A dry run does not commit the host file. The "path:" prefix makes
          # nix read the directory as it is, so the new file is visible.
          # home-manager has a flag for the result link.
          ${home-manager}/bin/home-manager build --flake "path:$flake" --no-out-link
        else
          ${home-manager}/bin/home-manager switch --flake "$flake" -b hm-bak
        fi
      ''
  );
}
