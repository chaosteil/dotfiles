{
  system = "aarch64-darwin";
  user = "dominykas";
  fullName = "Dominykas Djacenko";
  email = "dominykas@pierre.co";
  bookmarkPrefix = "dominykas";
  signingKey = "/Users/dominykas/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/d3834209a5ec5626d49827d4fc0ef457.pub";
  privateAssets = true;
  cameraLight = true;
  apps = [
    "_1password-cli"
    "pulumi"
    "pulumiPackages.pulumi-nodejs"
    "cmctl"
  ];
  casks = [
    "1password"
    "docker"
    "slack"
  ];
  dockApps = nixApps: [
    "${nixApps}/Google Chrome.app"
    "${nixApps}/Firefox.app"
    "/Applications/Rex.app"
    "/Applications/Slack.app"
    "${nixApps}/Notion.app"
    "/Applications/Notion Calendar.app"
    "/Applications/Todoist.app"
    "${nixApps}/Spotify.app"
    "/Applications/Discord.app"
    "/Applications/1Password.app"
  ];
}
