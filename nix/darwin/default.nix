{
  inputs,
  user,
  host,
  pkgs,
  ...
}:
let
  home = "/Users/${user}";
  nixApps = "/Applications/Nix Apps";
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  nixpkgs.hostPlatform = host.system;
  nixpkgs.overlays = [
    inputs.rust-overlay.overlays.default

    # These apps keep the code signature of the vendor. macOS refuses to open an
    # app when the bundle does not agree with that signature. Each patch below
    # removes a change that the nixpkgs build makes to a signed file.
    (final: prev: {
      # The DMG holds a resource fork on Resources/IntroShot.png. The unpack step
      # writes that fork to a separate "._IntroShot.png" file. This file is not
      # in the sealed manifest, so macOS reports "the app is damaged".
      scroll-reverser = prev.scroll-reverser.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          find "$out/Applications" -name '._*' -delete
        '';
      });

      # The fixup step writes nix store paths to the shebang lines of the shipped
      # scripts, for example Resources/senddoc and the Python framework. macOS
      # sees the new contents of these sealed files and refuses to open the app.
      libreoffice-bin = prev.libreoffice-bin.overrideAttrs (_: {
        dontPatchShebangs = true;
      });
    })
  ];
  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {
      inherit inputs user host;
      standalone = false;
    };
    users.${user}.imports = [
      ../options.nix
      ../home
      ../home/darwin.nix
    ];
  };

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  environment.systemPackages = [ pkgs.secretive ] ++ import ./apps.nix pkgs;

  system.stateVersion = 5;
  system.primaryUser = user;
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  users.users.${user} = {
    name = user;
    inherit home;
    shell = pkgs.fish;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleKeyboardUIMode = 2;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      AppleTemperatureUnit = "Celsius";
      InitialKeyRepeat = 35;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSTableViewDefaultSizeMode = 1;
      NSWindowShouldDragOnGesture = true;
    };

    ".GlobalPreferences" = {
      "com.apple.mouse.scaling" = -1.0;
      "com.apple.sound.beep.sound" = "/System/Library/Sounds/Morse.aiff";
    };

    dock = {
      autohide = true;
      magnification = true;
      tilesize = 43;
      largesize = 48;
      persistent-apps = [
        "${nixApps}/Firefox.app"
        "${nixApps}/Ghostty.app"
        "${nixApps}/Notion.app"
        "/Applications/Notion Calendar.app"
        "/Applications/Todoist.app"
        "${nixApps}/Spotify.app"
        "/Applications/Discord.app"
        "/System/Applications/iPhone Mirroring.app"
      ];
      persistent-others = [ "${home}/Downloads" ];
    };

    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
      FXRemoveOldTrashItems = true;
      NewWindowTarget = "Home";
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
    };

    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
    };

    screencapture.location = "${home}/Pictures/Screenshots";

    trackpad.TrackpadThreeFingerTapGesture = 0;

    WindowManager = {
      EnableTiledWindowMargins = false;
      HideDesktop = true;
    };
  };

  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      AppleMiniaturizeOnDoubleClick = false;
      NSAutomaticTextCompletionEnabled = false;
      WebAutomaticSpellingCorrectionEnabled = false;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.trackpad.scaling" = 1.0;
    };
    "com.apple.HIToolbox".AppleDictationAutoEnable = 0;
    "com.apple.screencapture" = {
      captureDelay = 5;
      type = "png";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
