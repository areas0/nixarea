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

      # launchers
      "$mod, D, exec, $menu"
      "ALT, SPACE, exec, $menu"
      "$mod, C, exec, walker -s clipboard"
      "$mod, W, exec, walker -s windows"

      "$mod, F, fullscreen"

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
    ++ (
      builtins.concatLists (
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
      )
    );
    bindl = [
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
    bindm = [
      "ALT, mouse:272, movewindow"
      "ALT, mouse:273, resizewindow"
    ];

    input = {
      kb_layout = "us,fr";
      kb_options = "grp:win_space_toggle";
      follow_mouse = "1";
      mouse_refocus = true;
      touchpad = {
        natural_scroll = "yes";
      };
    };

    general = {
      gaps_in = 5;
      gaps_out = 1;
      border_size = 1;
    };

    render = {
      cm_fs_passthrough = 2;
      cm_auto_hdr = 2;
    };

    decoration = {
      rounding = 10;

      blur = {
        enabled = true;
        size = 5;
        passes = 3;
      };
    };

    layerrule = [
      "blur on, match:namespace ^bar-"
      "blur_popups on, match:namespace ^bar-"
      "ignore_alpha 0.3, match:namespace ^bar-"
      "xray on, match:namespace ^bar-"
    ];

    workspace = [
      "r[1-4], monitor:eDP-1"
      "r[5-9], monitor:DP-7"
    ];

    monitor = [
      "eDP-1, 1920x1200@60, 0x0, 1"
      "desc:Iiyama North America PL2770H 0x30393235, 1920x1080@144, 1920x0, 1"
      "desc: BNQ BenQ LCD 89L03574019, 2560x1440@59.95, 3840x0, 1"
      # "DP-3,1920x1080@60.0,1920x0,1"
      # cm, hdredid, sdrbrightness, 1.25, sdrsaturation, 1.0,
      # "desc:Samsung Electric Company Odyssey G60SD HNAX701148, 2560x1440@360.00Hz, auto, 1.0, bitdepth, 10, vrr, 1, cm, hdr, sdrbrightness, 1.1, sdrsaturation, 1.0, sdrminluminance, 0, sdrmaxluminance, 200"
    ];

    monitorv2 = [
      {
        output = "DP-2";
        mode = "2560x1440@360.00Hz";
        position = "auto";
        scale = 1;
        sdr_min_luminance = 0;
        sdr_max_luminance = 200;
        cm = "hdredid";
        supports_hdr = 1;
        bitdepth = 10;
        vrr = 1;
        sdr_eotf = 2;
        supports_wide_color = 1;
        sdrbrightness = 1.1;
        sdrsaturation = 1.0;
      }
      {
        output = "DP-3";
        mode = "1920x1080@143.98100Hz";
        position = "1920x0";
        scale = 1;
        sdr_min_luminance = 0;
        sdr_max_luminance = 200;
        cm = "auto";
        supports_hdr = 0;
        bitdepth = 8;
        vrr = 1;
        sdr_eotf = 1;
        supports_wide_color = 0;
        sdrbrightness = 1.1;
        sdrsaturation = 1.0;
        transform = 3;
      }
    ];

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      force_default_wallpaper = 0;
    };

    windowrule = [
      "opacity 0.95, match:class code"
      "opacity 0.99, match:class zen-beta"

      # --- Gaming: Steam games ---
      "immediate on, match:class ^(steam_app)"
      "fullscreen on, match:class ^(steam_app)"
      "no_blur on, match:class ^(steam_app)"
      "no_shadow on, match:class ^(steam_app)"
      "no_anim on, match:class ^(steam_app)"

      # --- Gaming: Steam client ---
      "float on, match:class ^(steam)$"
      "float on, match:class ^(steam)$, match:title ^(Friends)"
      "float on, match:class ^(steam)$, match:title ^(Steam Settings)"

      # --- Gaming: Gamescope ---
      "immediate on, match:class ^(gamescope)"
      "fullscreen on, match:class ^(gamescope)"
      "no_blur on, match:class ^(gamescope)"
      "no_shadow on, match:class ^(gamescope)"
      "no_anim on, match:class ^(gamescope)"

      # --- Gaming: Launchers (float) ---
      "float on, match:class ^(lutris)"
      "float on, match:class ^(com.usebottles.bottles)"
      "float on, match:class ^(heroic)"
      "float on, match:class ^(net.davidotek.pupgui2)"

      # --- Gaming: Emulators ---
      "immediate on, match:class ^(retroarch)"
      "no_blur on, match:class ^(retroarch)"
      "no_shadow on, match:class ^(retroarch)"

      "immediate on, match:class ^(Ryujinx|ryubing)"
      "no_blur on, match:class ^(Ryujinx|ryubing)"
      "no_shadow on, match:class ^(Ryujinx|ryubing)"

      "immediate on, match:class ^(azahar|citra)"
      "no_blur on, match:class ^(azahar|citra)"
      "no_shadow on, match:class ^(azahar|citra)"

      # --- Gaming: Star Citizen ---
      "float on, match:class ^(rsi)"
      "immediate on, match:class ^(star_citizen|starcitizen)"
      "no_blur on, match:class ^(star_citizen|starcitizen)"
      "no_shadow on, match:class ^(star_citizen|starcitizen)"
      "no_anim on, match:class ^(star_citizen|starcitizen)"

      # --- Gaming: Wine/Proton fallback ---
      "no_blur on, match:class \\.exe$"
      "no_shadow on, match:class \\.exe$"
    ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    # resize submap (i3-style resize mode)
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

    # game mode submap: disables compositor keybinds for gaming
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
