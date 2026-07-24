{
  pkgs,
  config,
  lib,
  additionalConfig,
  ...
}:
let
  isNvidia = additionalConfig.isNvidia or false;
  colors = config.lib.stylix.colors;

  # Same pipelines as the Hyprland screenshot binds.
  regionShot = ''grim -g \"$(slurp)\" - | tee ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png | wl-copy'';
  fullShot = "grim - | tee ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png | wl-copy";

  workspaceBinds = lib.concatStrings (
    lib.genList (
      i:
      let
        ws = toString (i + 1);
      in
      ''
        Mod+${ws} { focus-workspace ${ws}; }
        Mod+Shift+${ws} { move-column-to-workspace ${ws}; }
      ''
    ) 9
  );
in
{
  # X11 apps (Steam, games) under niri. niri spawns xwayland-satellite itself
  # and exports DISPLAY; the explicit path below avoids relying on PATH.
  home.packages = [ pkgs.xwayland-satellite ];

  # No home-manager niri module in release-26.05 and no stylix target: raw KDL,
  # with stylix colors hand-wired into the focus ring. Mirrors the Hyprland
  # setup (home/desktop/hyprland/) where niri has an equivalent; dropped bits
  # (dwindle, groups, submaps, HDR, per-window blur/shadow/tearing) have none.
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us,fr"
                options "grp:win_space_toggle"
            }
        }
        touchpad {
            natural-scroll
        }
        focus-follows-mouse
    }

    // Workstation monitor, same EDID description match as hyprland.lua. The
    // HDR/10-bit/sdr-tuning knobs have no niri equivalent. VRR is on-demand:
    // it engages only for windows carrying the variable-refresh-rate rule
    // (games) instead of the whole desktop.
    output "Samsung Electric Company Odyssey G60SD HNAX701148" {
        // niri matches the refresh exactly against `niri msg outputs`, which
        // reports 359.999 (not 360.000) — a mismatch silently falls back to
        // the preferred 120 Hz mode.
        mode "2560x1440@359.999"
        variable-refresh-rate on-demand=true
        scale 1
        // Right of the portrait Acer (1080 logical px wide), centered
        // vertically against its 1920 px height: (1920 - 1440) / 2 = 240.
        position x=1080 y=240
    }

    // Secondary: portrait Acer. After transform the logical size is 1080x1920.
    output "Acer Technologies XB253Q TH5EE0058521" {
        mode "1920x1080@143.981"
        transform "270"
        scale 1
        position x=0 y=0
    }

    // Per-compositor session env, duplicated from the Hyprland env block so
    // the Hyprland session stays untouched.
    environment {
        NIXOS_OZONE_WL "1"
        MOZ_ENABLE_WAYLAND "1"
        MOZ_WEBRENDER "1"
        _JAVA_AWT_WM_NONREPARENTING "1"
        QT_WAYLAND_DISABLE_WINDOWDECORATION "1"
        QT_QPA_PLATFORM "wayland"
        SDL_VIDEODRIVER "wayland"
        GDK_BACKEND "wayland"
    ${lib.optionalString isNvidia ''
      GBM_BACKEND "nvidia-drm"
      __GLX_VENDOR_LIBRARY_NAME "nvidia"
      LIBVA_DRIVER_NAME "nvidia"
    ''}}

    spawn-at-startup "noctalia"
    spawn-at-startup "sh" "-c" "wl-paste --watch cliphist store"

    xwayland-satellite {
        path "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"

    layout {
        gaps 2
        focus-ring {
            width 1
            active-color "#${colors.base0D}"
            inactive-color "#${colors.base03}"
        }
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+Return { spawn "kitty"; }
        Mod+E { spawn "thunar"; }
        Mod+Shift+Q { close-window; }
        Mod+Shift+E { spawn "noctalia" "msg" "session" "lock"; }
        Mod+Shift+I { quit; }
        Mod+V { toggle-window-floating; }
        Mod+F { fullscreen-window; }

        Mod+D { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
        Alt+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
        Mod+W { spawn "noctalia" "msg" "window-switcher"; }
        Mod+C { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }

        Mod+Period { spawn "noctalia" "msg" "desktop-widgets-edit"; }
        Mod+Shift+Period { spawn "noctalia" "msg" "desktop-widgets-toggle"; }

        Mod+O { toggle-overview; }

        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-up; }
        Mod+Down { focus-window-down; }
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        Mod+J { focus-window-down; }

        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up { move-window-up; }
        Mod+Shift+Down { move-window-down; }
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+J { move-window-down; }

        // Monitor crossing (keyboard focus doesn't cross output edges on its
        // own in niri, unlike Hyprland's movefocus).
        Mod+Ctrl+Left { focus-monitor-left; }
        Mod+Ctrl+Right { focus-monitor-right; }
        Mod+Ctrl+H { focus-monitor-left; }
        Mod+Ctrl+L { focus-monitor-right; }
        Mod+Ctrl+Shift+Left { move-column-to-monitor-left; }
        Mod+Ctrl+Shift+Right { move-column-to-monitor-right; }
        Mod+Ctrl+Shift+H { move-column-to-monitor-left; }
        Mod+Ctrl+Shift+L { move-column-to-monitor-right; }

        // Column sizing (replaces the Hyprland resize submap; no submaps in niri).
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { reset-window-height; }
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Comma { consume-window-into-column; }
        Mod+BracketLeft { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }

    ${workspaceBinds}
        Mod+Shift+S { spawn "bash" "-c" "${regionShot}"; }
        Mod+Shift+P { spawn "bash" "-c" "${fullShot}"; }
        Print { screenshot; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down"; }
        XF86AudioMute allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }
        XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

        XF86MonBrightnessUp { spawn "noctalia" "msg" "brightness-up"; }
        XF86MonBrightnessDown { spawn "noctalia" "msg" "brightness-down"; }

        XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
    }

    window-rule {
        match app-id="^code$"
        opacity 0.95
    }
    window-rule {
        match app-id="^zen-beta$"
        opacity 0.99
    }

    // Gaming — Hyprland's immediate/no_blur/no_shadow/no_anim rules have no
    // niri counterpart; per-window VRR is the useful analogue.
    window-rule {
        match app-id="^steam_app"
        match app-id="^gamescope"
        open-fullscreen true
        variable-refresh-rate true
    }
    window-rule {
        match app-id="^steam$"
        match app-id="^(lutris|com.usebottles.bottles|heroic|net.davidotek.pupgui2)$"
        match app-id="^rsi"
        open-floating true
    }
    window-rule {
        match app-id="^(star_citizen|starcitizen)"
        match app-id="^(Ryujinx|ryubing|retroarch|azahar|citra)"
        variable-refresh-rate true
    }
  '';
}
