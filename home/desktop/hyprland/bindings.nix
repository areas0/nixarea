{ ... }:
let
  # Full IPC command per action, in v5's flat `noctalia msg <command>` scheme.
  # Mirrors the `nc` table in hyprland.lua (the active runtime config); this
  # hyprlang set is the fallback used only if the lua file is removed.
  nc = {
    lock = "noctalia msg session lock";
    launcher = "noctalia msg panel-toggle launcher";
    windows = "noctalia msg window-switcher";
    clipboard = "noctalia msg panel-toggle clipboard";
    widgetsEdit = "noctalia msg desktop-widgets-edit";
    widgetsToggle = "noctalia msg desktop-widgets-toggle";
    volUp = "noctalia msg volume-up";
    volDown = "noctalia msg volume-down";
    volMute = "noctalia msg volume-mute";
    briUp = "noctalia msg brightness-up";
    briDown = "noctalia msg brightness-down";
  };
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod SHIFT, Q, killactive"
      "$mod, RETURN, exec, $terminal"
      "$mod SHIFT, E, exec, ${nc.lock}"
      "$mod SHIFT, I, exit"
      "$mod, E, exec, $fileManager"
      "$mod, V, togglefloating"
      "$mod, F, fullscreen"

      # launcher
      "$mod, D, exec, ${nc.launcher}"
      "ALT, SPACE, exec, ${nc.launcher}"
      "$mod, W, exec, ${nc.windows}"
      "$mod, C, exec, ${nc.clipboard}"

      # desktop widgets
      "$mod, period, exec, ${nc.widgetsEdit}"
      "$mod SHIFT, period, exec, ${nc.widgetsToggle}"

      # dwindle layout
      "$mod, P, pseudo"
      "$mod, O, togglesplit"
    ]
    ++ [

      # window groups
      "$mod, G, togglegroup"
      "$mod ALT, Tab, changegroupactive, f"
      "$mod ALT SHIFT, Tab, changegroupactive, b"

      # app focus shortcuts
      "$mod, Z, exec, bash -c 'hyprctl dispatch focuswindow class:zen-beta'"
      "$mod, S, exec, bash -c 'hyprctl dispatch focuswindow class:slack'"

      # focus (arrow keys)
      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"

      # focus (hjkl)
      "$mod, H, movefocus, l"
      "$mod, J, movefocus, d"
      "$mod, K, movefocus, u"
      "$mod, L, movefocus, r"

      # move window (arrow keys)
      "$mod SHIFT, left, movewindow, l"
      "$mod SHIFT, right, movewindow, r"
      "$mod SHIFT, up, movewindow, u"
      "$mod SHIFT, down, movewindow, d"

      # move window (hjkl)
      "$mod SHIFT, H, movewindow, l"
      "$mod SHIFT, J, movewindow, d"
      "$mod SHIFT, K, movewindow, u"
      "$mod SHIFT, L, movewindow, r"

      # screenshots
      "$mod SHIFT, S, exec, bash -c 'grim -g \"$(slurp)\" - | tee ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png | wl-copy'"
      "$mod SHIFT, P, exec, bash -c 'grim - | tee ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png | wl-copy'"

      # audio
      ", XF86AudioRaiseVolume, exec, ${nc.volUp}"
      ", XF86AudioLowerVolume, exec, ${nc.volDown}"
      ", XF86AudioMute, exec, ${nc.volMute}"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

      # brightness
      ", XF86MonBrightnessUp, exec, ${nc.briUp}"
      ", XF86MonBrightnessDown, exec, ${nc.briDown}"

      # resize submap
      "$mod, R, submap, resize"

      # game mode submap
      "$mod, F9, submap, gamemode"
    ]
    ++ (builtins.concatLists (
      builtins.genList (
        i:
        let
          ws = i + 1;
        in
        [
          "$mod, code:1${toString i}, workspace, ${toString ws}"
          "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
        ]
      ) 9
    ));

    bindl = [
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];

    bindm = [
      "ALT, mouse:272, movewindow"
      "ALT, mouse:273, resizewindow"
    ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    submap = resize
    binde = , right, resizeactive, 30 0
    binde = , left, resizeactive, -30 0
    binde = , up, resizeactive, 0 -30
    binde = , down, resizeactive, 0 30
    binde = , l, resizeactive, 30 0
    binde = , h, resizeactive, -30 0
    binde = , k, resizeactive, 0 -30
    binde = , j, resizeactive, 0 30
    bind = , escape, submap, reset
    bind = , Return, submap, reset
    submap = reset

    submap = gamemode
    bind = $mod, F9, submap, reset
    bind = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
    bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    bindl = , XF86AudioPlay, exec, playerctl play-pause
    bindl = , XF86AudioNext, exec, playerctl next
    bindl = , XF86AudioPrev, exec, playerctl previous
    submap = reset
  '';
}
