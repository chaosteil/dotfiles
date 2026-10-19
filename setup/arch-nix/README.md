# Arch setup for the nix layout

This directory sets up an Arch host for the nix configuration in `nix/`.
Arch supplies only the host parts. Nix supplies the rest.

## The three layers

1. Arch host packages: the kernel, the firmware, the drivers, the
   system services and the parts of the desktop that the host must
   supply. The lists in this directory name these packages.
2. The system layer: `nix/system/`. system-manager applies it as root.
   It writes files in `/etc`, turns on systemd units and links the GPU
   drivers.
3. Home Manager: `nix/home/`. It installs the desktop apps and the
   tools for the user, and it writes the user configuration.

## A new machine

1. Install Arch.
2. Clone this repository to `~/dotfiles`.
3. Run `~/dotfiles/setup/arch-nix/install.sh`.

The script does these steps. You can run it again and again:

1. If a list has a `lib32-` package, it turns on `[multilib]` in
   `/etc/pacman.conf`.
2. It adds the names in `ignorepkg.<host>.txt` to `IgnorePkg` in
   `/etc/pacman.conf`.
3. It installs the pacman packages with `pacman -Syu --needed`. Steps 3
   and 4 skip a package of `ignorepkg.<host>.txt` that is installed
   already, so that pacman does not upgrade it.
4. If `yay` is not installed, it builds `yay` from the AUR. Then it
   installs the AUR packages.
5. It starts the nix daemon. If `/etc/nix/nix.conf` does not turn on
   flakes, it turns them on. system-manager replaces this file later.
6. It runs the nix bootstrap: Home Manager, then system-manager.
7. It prints the steps that stay manual.

After the first system-manager switch, run
`sudo systemctl restart nix-daemon`.

## The package lists

Each list has one package on each line. `#` starts a comment. The host
name is the output of `uname -n` without the domain.

- `pacman.txt`: the pacman packages of all hosts.
- `pacman.<host>.txt`: the pacman packages of one host.
- `aur.txt`: the AUR packages of all hosts.
- `aur.<host>.txt`: the AUR packages of one host.
- `ignorepkg.<host>.txt`: the packages that `pacman -Syu` does not
  upgrade on one host.

The script reads a list only if the file exists.

## Add a host

1. Make the files `pacman.<host>.txt`, `aur.<host>.txt` and
   `ignorepkg.<host>.txt` that the host needs.
2. Add the host file `nix/hosts/<host>.nix`. The nix bootstrap writes a
   simple host file if there is none.

## Compare the lists with the machine

Run `setup/arch-nix/install.sh --check`. The script makes no changes.
It prints two groups:

- Installed but not listed: explicit packages (`pacman -Qqe`) that no
  list names.
- Listed but not installed: listed packages that are not installed.
  A listed package that is installed as a dependency counts as
  installed.

The exit status is 1 if a group is not empty.
