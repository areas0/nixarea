{ config, lib, ... }:
let
  c = config.lib.stylix.colors;
in
{
  programs.hyprlock.settings = {
    general = {
      disable_loading_bar = true;
      hide_cursor = false;
      no_fade_in = true;
    };

    background = lib.mkForce [
      {
        monitor = "";
        path = "screenshot";
        blur_passes = 2;
        blur_size = 5;
        color = "rgb(${c.base00})";
      }
    ];

    input-field = lib.mkForce [
      {
        size = "300, 50";
        outline_thickness = 1;
        outer_color = "rgb(${c.base0D})";
        inner_color = "rgb(${c.base02})";
        font_color = "rgb(${c.base05})";
        fade_on_empty = false;
        placeholder_text = ''<span foreground="##${c.base04}">Password...</span>'';
        dots_spacing = 0.2;
        dots_center = true;
      }
    ];

    label = lib.mkForce [
      {
        monitor = "";
        text = "$TIME";
        font_size = 50;
        color = "rgb(${c.base0D})";
        position = "0, 150";
        valign = "center";
        halign = "center";
      }
      {
        monitor = "";
        text = "cmd[update:3600000] date +'%a %d %b %Y'";
        font_size = 20;
        color = "rgb(${c.base0D})";
        position = "0, 50";
        valign = "center";
        halign = "center";
      }
    ];
  };
}
