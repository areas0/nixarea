{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = [
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
      "ALT, SPACE, exec, $menu"

      # shortcut to set current window to fullscreen
      "$mod, F, fullscreen"

      # rule to switch to focus to existing window of zen-browser or launch it if not running
      "$mod, Z, exec, bash -c 'hyprctl dispatch focuswindow class:zen-beta'"
      "$mod, S, exec, bash -c 'hyprctl dispatch focuswindow class:slack'"

      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"
      "$mod SHIFT, left, movewindow, l"
      "$mod SHIFT, right, movewindow, r"
      "$mod SHIFT, up, movewindow, u"
      "$mod SHIFT, down, movewindow, d"

      "$mod SHIFT, S, exec, bash -c 'grim -g \"$(slurp)\"'"

      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"

      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ]
    ++ (
      # workspaces
      # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
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
        passes = 1;
      };

      #drop_shadow = "yes";
      #shadow_range = 4;
      #shadow_render_power = 3;
      #"col.shadow" = "rgba(1a1a1aee)";
    };

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

    windowrule = [
      "opacity 0.95, match:class code"
      "opacity 0.99, match:class zen-beta"
    ];
  };
}
