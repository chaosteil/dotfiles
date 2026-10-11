{
  config,
  inputs,
  lib,
  pkgs,
  link,
  namedPackages,
  ...
}:

{
  imports = [ ./hyprland.nix ];

  targets.genericLinux.enable = true;

  # Home Manager builds the drivers. system-manager links them.
  targets.genericLinux.gpu.nvidia = lib.mkIf (config.local.nvidia != null) {
    enable = true;
    inherit (config.local.nvidia) version sha256;
  };

  # system-manager owns /run/opengl-driver, not the setup package of the module.
  home.activation.checkExistingGpuDrivers = lib.mkForce (
    lib.hm.dag.entryAnywhere ''
      existing=$(readlink /run/opengl-driver || true)
      if [[ "$existing" != "${config.targets.genericLinux.gpu.drivers}" ]]; then
        warnEcho "/run/opengl-driver does not point to the GPU drivers of this configuration."
        warnEcho "Run:"
        warnEcho "  system-manager switch --flake ~/dotfiles/nix --sudo"
      fi
    ''
  );

  # Buncha desktop apps
  home.packages =
    namedPackages [
      "blender"
      "firefox-bin"
      "ghostty"
      "godot"
      "google-chrome"
      "openscad-unstable"
      "spotify"
      "zoom-us"
    ]
    ++ [ inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ lib.optional config.local.privateAssets pkgs.private-assets;

  # The nix NVIDIA libraries must match the host driver.
  home.activation.checkNvidiaVersion = lib.mkIf (config.local.nvidia != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! grep -qF ' ${config.local.nvidia.version} ' /proc/driver/nvidia/version 2>/dev/null; then
        warnEcho "The NVIDIA driver is not version ${config.local.nvidia.version}."
        warnEcho "Get the hash of the driver of the host:"
        warnEcho "  nix store prefetch-file https://download.nvidia.com/XFree86/Linux-x86_64/<version>/NVIDIA-Linux-x86_64-<version>.run"
        warnEcho "Write the version and the hash in ~/dotfiles/nix/hosts/$(uname -n).nix."
        warnEcho "Then run:"
        warnEcho "  system-manager switch --flake ~/dotfiles/nix --sudo"
        warnEcho "  home-manager switch --flake ~/dotfiles/nix"
      fi
    ''
  );

  fonts.fontconfig.enable = lib.mkIf config.local.privateAssets true;

  # The ssh-agent.socket unit of the host, also for systemd user services.
  home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  systemd.user.sessionVariables.SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/ssh-agent.socket";
  xdg.configFile."systemd/user/sockets.target.wants/ssh-agent.socket".source =
    config.lib.file.mkOutOfStoreSymlink "/usr/lib/systemd/user/ssh-agent.socket";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".AddKeysToAgent = "yes";
  };

  xdg.configFile."i3".source = link "i3/.config/i3";
}
