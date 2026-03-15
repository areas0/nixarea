{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod SHIFT, Q, killactive"
      "$mod, RETURN, exec, $terminal"
      "$mod SHIFT, E, exec, hyprlock"
      "$mod SHIFT, I, exit"
      "$mod, E, exec, $fileManager"
      "$mod, V, togglefloating"
      "$mod, F, fullscreen"

      # launchers
      "$mod, D, exec, $menu"
      "ALT, SPACE, exec, $menu"
      "$mod, C, exec, walker -s clipboard"
      "$mod, W, exec, walker -s windows"

      # dwindle layout
      "$mod, P, pseudo"
      "$mod, O, togglesplit"

      # window groups
      "$mod, G, togglegroup"
      "$mod, Tab, changegroupactive, f"
      "$mod SHIFT, Tab, changegroupactive, b"

      # app focus shortcuts
      "$mod, Z, exec, bash -c 'hyprctl dispatch focuswindow class:zen-beta'"
      "$mod, S, exec, bash -c 'hyprctl dispatch focuswindow class:slack'"

      ''$mod SHIFT, B, exec, bash -c 'CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/hyprpanel/config.json"; STATE="''${XDG_RUNTIME_DIR:-/tmp}/hyprpanel-bar-position"; CUR=$(cat "$STATE" 2>/dev/null || echo top); if [ "$CUR" = "top" ]; then NEXT=bottom; else NEXT=top; fi; [ -L "$CONFIG" ] && cp --remove-destination "$(readlink -f "$CONFIG")" "$CONFIG" && chmod u+w "$CONFIG"; jq --arg loc "$NEXT" ".\"theme.bar.location\" = \$loc" "$CONFIG" > "$CONFIG.tmp" && mv -f "$CONFIG.tmp" "$CONFIG"; hyprpanel restart; echo "$NEXT" > "$STATE"' ''

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
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

      # brightness
      ", XF86MonBrightnessUp, exec, brightnessctl s +5%"
      ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"

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
    bindm = ALT, mouse:272, movewindow
    bindm = ALT, mouse:273, resizewindow
    submap = reset
  '';
}
