{ ... }:
{
  programs.zen-browser = {
    enable = true;
    configPath = ".zen";
    profiles.default = {
      name = "Default Profile";
      path = "p3h34s5g.Default Profile";
      isDefault = true;
    };
  };

  stylix.targets.zen-browser.profileNames = [ "default" ];
}
