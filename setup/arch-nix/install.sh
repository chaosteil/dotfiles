#!/usr/bin/env bash
# Install the Arch packages of this host, then run the nix bootstrap.
# Safe to run again. See README.md.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

usage() {
  cat <<EOF
usage: install.sh [--check | --help]

Install the Arch packages of this host from the lists in
$here, and then apply the nix configuration.

  --check  Make no changes. Compare the package lists with the
           installed packages. The exit status is 1 if they are
           different.
  --help   Show this text.
EOF
}

check=0
for arg in "$@"; do
  case "$arg" in
    --check) check=1 ;;
    --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

# The host name without the domain, as in nix/bootstrap.nix.
host="$(uname -n)"
host="${host%%.*}"

# Print the package names in the list files that exist, one on each
# line. "#" starts a comment.
read_lists() {
  local file
  for file in "$@"; do
    if [ -f "$here/$file" ]; then
      sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$here/$file"
    fi
  done
}

mapfile -t pacman_pkgs < <(read_lists pacman.txt "pacman.$host.txt")
mapfile -t aur_pkgs < <(read_lists aur.txt "aur.$host.txt")
mapfile -t ignore_pkgs < <(read_lists "ignorepkg.$host.txt")

if [ "$check" = 1 ]; then
  listed="$(printf '%s\n' "${pacman_pkgs[@]}" "${aur_pkgs[@]}" | sed '/^$/d' | sort -u)"
  # Dependencies count as installed.
  not_listed="$(comm -23 <(pacman -Qqe | sort -u) <(printf '%s\n' "$listed"))"
  not_installed="$(comm -23 <(printf '%s\n' "$listed") <(pacman -Qq | sort -u))"

  echo "Installed but not listed:"
  if [ -n "$not_listed" ]; then
    while IFS= read -r pkg; do
      echo "  $pkg"
    done <<< "$not_listed"
  else
    echo "  (none)"
  fi
  echo "Listed but not installed:"
  if [ -n "$not_installed" ]; then
    while IFS= read -r pkg; do
      echo "  $pkg"
    done <<< "$not_installed"
  else
    echo "  (none)"
  fi

  if [ -n "$not_listed" ] || [ -n "$not_installed" ]; then
    exit 1
  fi
  exit 0
fi

pacman_conf=/etc/pacman.conf

# 1. If a list has a lib32- package, turn on the [multilib] section.
if grep -q '^lib32-' <<< "$(printf '%s\n' "${pacman_pkgs[@]}" "${aur_pkgs[@]}")"; then
  if ! grep -q '^\[multilib\]' "$pacman_conf"; then
    echo "==> Turn on [multilib] in $pacman_conf"
    if grep -q '^#\[multilib\]' "$pacman_conf"; then
      sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#Include/Include/}' "$pacman_conf"
    else
      printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' |
        sudo tee -a "$pacman_conf" > /dev/null
    fi
  fi
fi

# 2. Pin the ignorepkg names before the upgrade. On a new machine, pacman
#    asks once to install a pinned package: answer yes.
read -ra ignored <<< "$(sed -n 's/^IgnorePkg[[:space:]]*=//p' "$pacman_conf" | tr '\n' ' ')"
missing=()
for pkg in "${ignore_pkgs[@]}"; do
  found=0
  for name in "${ignored[@]}"; do
    if [ "$name" = "$pkg" ]; then
      found=1
    fi
  done
  if [ "$found" = 0 ]; then
    missing+=("$pkg")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "==> Add ${missing[*]} to IgnorePkg in $pacman_conf"
  if grep -q '^IgnorePkg' "$pacman_conf"; then
    sudo sed -i "0,/^IgnorePkg/s/^IgnorePkg.*/& ${missing[*]}/" "$pacman_conf"
  else
    sudo sed -i "/^\[options\]/a IgnorePkg = ${missing[*]}" "$pacman_conf"
  fi
fi

# Drop installed pinned packages from the install lists, or pacman offers
# to upgrade them.
skip_ignored() {
  local pkg ignored
  for pkg in "$@"; do
    for ignored in "${ignore_pkgs[@]}"; do
      if [ "$pkg" = "$ignored" ] && pacman -Qq "$pkg" > /dev/null 2>&1; then
        continue 2
      fi
    done
    echo "$pkg"
  done
}
mapfile -t install_pacman_pkgs < <(skip_ignored "${pacman_pkgs[@]}")
mapfile -t install_aur_pkgs < <(skip_ignored "${aur_pkgs[@]}")

# 3. Install the pacman packages.
echo "==> Install the pacman packages"
sudo pacman -Syu --needed "${install_pacman_pkgs[@]}"

# 4. Install yay, then the AUR packages.
if ! command -v yay > /dev/null; then
  echo "==> Build yay from the AUR"
  (
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    cd "$tmp/yay"
    makepkg -si
  )
fi
if [ "${#install_aur_pkgs[@]}" -gt 0 ]; then
  echo "==> Install the AUR packages"
  yay -S --needed "${install_aur_pkgs[@]}"
fi

# 5. Start the nix daemon. The first nix run needs flakes.
#    system-manager replaces /etc/nix/nix.conf later.
echo "==> Start the nix daemon"
sudo systemctl enable --now nix-daemon
if ! grep -q '^[[:space:]]*experimental-features' /etc/nix/nix.conf 2> /dev/null; then
  echo "==> Turn on flakes in /etc/nix/nix.conf"
  echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf > /dev/null
fi

# 6. Apply Home Manager, and then system-manager.
echo "==> Run the nix bootstrap"
nix run "$repo/nix"

# 7. The steps that stay manual.
cat <<'EOF'

==> Do these steps manually:
- Update the firmware:
    fwupdmgr refresh && fwupdmgr update
- Test suspend and resume. If the screen is black after resume, run:
    sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate
- For a dual boot with Windows, set RealTimeIsUniversal on Windows, so
  that the two systems agree on the clock.
EOF
