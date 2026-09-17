{
  inputs,
  lib,
  user,
  host,
  pkgs,
  config,
  ...
}:
let
  home = "/Users/${user}";
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./options.nix
  ];

  nixpkgs.hostPlatform = host.system;
  nixpkgs.overlays = import ../overlays.nix inputs;
  nixpkgs.config.allowUnfree = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {
      inherit inputs user host;
      standalone = false;
    };
    users.${user}.imports = [ inputs.self.homeModules.darwin ];
  };

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Secretive MUST be in /Applications
  environment.systemPackages = [ pkgs.secretive ] ++ config.local.apps;

  # nix-darwin puts these in "/Library/Fonts/Nix Fonts".
  fonts.packages = lib.optional config.local.privateAssets pkgs.private-assets;

  # nix-homebrew installs the brew command.
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;

    # We manage these ourselves
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };

  homebrew = {
    enable = true;
    casks = config.local.casks;
    onActivation = {
      autoUpdate = true;
      upgrade = false;
      cleanup = "none";
    };
  };

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
      AppleMeasurementUnits = "Inches";
      AppleMetricUnits = 0;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      AppleTemperatureUnit = "Celsius";
      AppleWindowTabbingMode = "fullscreen";
      InitialKeyRepeat = 35;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSTableViewDefaultSizeMode = 1;
      NSWindowShouldDragOnGesture = true;
      _HIHideMenuBar = false;
      "com.apple.keyboard.fnState" = false;
      "com.apple.springing.delay" = 0.5;
      "com.apple.springing.enabled" = true;
      "com.apple.trackpad.forceClick" = true;
    };

    ".GlobalPreferences" = {
      "com.apple.mouse.scaling" = -1.0;
      "com.apple.sound.beep.sound" = "/System/Library/Sounds/Morse.aiff";
    };

    ActivityMonitor.OpenMainWindow = false;

    # The values are the menu bar icon state. Bluetooth and Focus use
    # "show when active", which nix-darwin cannot set.
    controlcenter = {
      AirDrop = false;
      Display = false;
      Sound = true;
    };

    dock = {
      autohide = true;
      magnification = true;
      tilesize = 43;
      largesize = 48;
      persistent-apps = config.local.dockApps;
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

    hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";

    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
    };

    screencapture = {
      location = "${home}/Pictures/Screenshots";
      target = "file";
      type = "png";
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    trackpad = {
      ActuateDetents = true;
      Clicking = false;
      DragLock = false;
      Dragging = false;
      FirstClickThreshold = 1;
      ForceSuppressed = false;
      SecondClickThreshold = 1;
      TrackpadCornerSecondaryClick = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadMomentumScroll = true;
      TrackpadPinch = true;
      TrackpadRightClick = true;
      TrackpadRotate = true;
      TrackpadThreeFingerDrag = false;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    };

    WindowManager = {
      AppWindowGroupingBehavior = true;
      AutoHide = false;
      EnableTiledWindowMargins = false;
      GloballyEnabled = false;
      HideDesktop = true;
      StageManagerHideWidgets = false;
      StandardHideWidgets = false;
    };
  };

  system.defaults.CustomUserPreferences = {
    NSGlobalDomain = {
      AppleMiniaturizeOnDoubleClick = false;
      NSAutomaticTextCompletionEnabled = false;
      WebAutomaticSpellingCorrectionEnabled = false;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.sound.beep.flash" = 0;
      "com.apple.trackpad.scaling" = 1.0;
    };
    "com.apple.HIToolbox".AppleDictationAutoEnable = 0;
    "com.apple.screencapture".captureDelay = 5;
    # Stats (the "stats" cask). Each "<module>_state" key turns a menu
    # bar module on or off. The keys with a timestamp, the remote id and
    # the menu bar positions are runtime state, so they are not here.
    "eu.exelban.Stats" = {
      LaunchAtLoginNext = true;

      CPU_state = true;
      CPU_widget = "line_chart";
      CPU_line_chart_box = false;
      CPU_line_chart_color = "utilization";
      CPU_line_chart_frame = false;
      CPU_line_chart_label = false;
      CPU_line_chart_value = false;
      CPU_bar_chart_box = false;
      CPU_bar_chart_color = "system";
      CPU_bar_chart_frame = false;
      CPU_bar_chart_label = false;

      RAM_state = true;
      RAM_widget = "bar_chart";
      RAM_bar_chart_box = false;
      RAM_bar_chart_label = false;

      Network_state = true;
      Network_widget = "network_chart";
      Network_base = "byte";
      Network_network_chart_box = false;
      Network_network_chart_frame = false;
      Network_speed_icon = "dots";
      Network_speed_units = true;
      Network_speed_value = true;

      Battery_state = false;
      Disk_state = false;
      Disk_widget = "bar_chart";
      GPU_state = false;
      GPU_widget = "";
      Sensors_state = false;
      Sensors_widget = "";
    };
  };

  # The open file limits. The first daemon sets the kernel limits. The
  # second daemon sets the limit that launchd gives to each process.
  # Both run at boot and when nix-darwin loads them at activation.
  launchd.daemons.sysctl-maxfiles.serviceConfig = {
    ProgramArguments = [
      "/usr/sbin/sysctl"
      "-w"
      "kern.maxfiles=10485760"
      "kern.maxfilesperproc=1048576"
    ];
    RunAtLoad = true;
  };

  launchd.daemons.limit-maxfiles.serviceConfig = {
    ProgramArguments = [
      "/bin/launchctl"
      "limit"
      "maxfiles"
      "65536"
      "524288"
    ];
    RunAtLoad = true;
    ServiceIPC = false;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
