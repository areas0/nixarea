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
}
