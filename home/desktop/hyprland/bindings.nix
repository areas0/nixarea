{ ... }:
{
  wayland.windowManager.hyprland.settings.bind =
    [
      "$mod, Q, killActive"
      "$mod, RETURN, exec, $terminal"
      "$mod SHIFT, Q, killactive"
      "$mod SHIFT, E, exec, hyprlock"
      "$mod SHIFT, I, exit"
      "$mod, E, exec, $fileManager"
      "$mod, V, togglefloating"
      "$mod, D, exec, $menu"
      "$mod, P, pseudo, # dwindle"
      "$mod, J, togglesplit, # dwindle"
      "$mod, F, exec, firefox"

      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"
      "SUPER_SHIT, left, movewindow, l"
      "SUPER_SHIT, right, movewindow, r"
      "SUPER_SHIT, up, movewindow, u"
      "SUPER_SHIT, down, movewindow, d"

    ]
    ++ (
      # workspaces
      # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
      builtins.concatLists (builtins.genList
        (i:
          let ws = i + 1;
          in [
            "$mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        )
        9)
    );
  wayland.windowManager.hyprland.settings.bindm = [
    "ALT, mouse:272, movewindow"
    "ALT, mouse:273, resizeWindow"
  ];

  wayland.windowManager.hyprland.settings.input = {
    kb_layout = "us,fr";
    kb_options = "grp:win_space_toggle";
    follow_mouse = "1";
    mouse_refocus = true;
    touchpad = {
      natural_scroll = "yes";
    };
  };

  wayland.windowManager.hyprland.settings.general = {
    gaps_in = 5;
    gaps_out = 1;
    border_size = 1;
  };
}
