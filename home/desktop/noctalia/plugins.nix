{ ... }:
let
  officialPlugins = "https://github.com/noctalia-dev/noctalia-plugins";

  mkPlugin = name: {
    ${name} = {
      enabled = true;
      sourceUrl = officialPlugins;
    };
  };
in
{
  programs.noctalia-shell.plugins = {
    sources = [
      {
        enabled = true;
        name = "Official Noctalia Plugins";
        url = officialPlugins;
      }
    ];

    states =
      mkPlugin "privacy-indicator"
      // mkPlugin "polkit-agent"
      // mkPlugin "keybind-cheatsheet"
      // mkPlugin "vscode-provider"
      // mkPlugin "file-search"
      // mkPlugin "openhue"
      // mkPlugin "network-indicator";
  };
}
