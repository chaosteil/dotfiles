{
  config,
  inputs,
  user,
  host,
  pkgs,
  ...
}:
let
  home = "/Users/${user}";
  hmApps = "${home}/${config.home-manager.users.${user}.targets.darwin.copyApps.directory}";
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  nixpkgs.hostPlatform = host.system;
  nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
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
        "${hmApps}/Firefox.app"
        "${hmApps}/Ghostty.app"
        "${hmApps}/Notion.app"
        "/Applications/Notion Calendar.app"
        "/Applications/Todoist.app"
        "${hmApps}/Spotify.app"
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
