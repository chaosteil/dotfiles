{
  inputs,
  user,
  system,
  ...
}:
{
  nixpkgs.hostPlatform = system;
  nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];

  system.stateVersion = 5;
  system.primaryUser = user;
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
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
        "/Applications/Firefox.app"
        "/Applications/Ghostty.app"
        "/Applications/Notion.app"
        "/Applications/Notion Calendar.app"
        "/Applications/Todoist.app"
        "/Applications/Spotify.app"
        "/Applications/Discord.app"
        "/System/Applications/iPhone Mirroring.app"
      ];
      persistent-others = [ "/Users/${user}/Downloads" ];
    };

    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
      FXRemoveOldTrashItems = true;
      NewWindowTarget = "Home";
      _FXSortFoldersFirst = true;
    };

    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
    };

    screencapture.location = "/Users/${user}/Pictures/Screenshots";

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
    "com.apple.screencapture".captureDelay = 5;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
