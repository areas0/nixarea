{ pkgs-unstable, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    systemd.enableXdgAutostart = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$noctalia" = "noctalia-shell ipc call";

      exec-once = [
        "code"
        "env QT_QPA_PLATFORMTHEME= noctalia-shell"
        "wl-paste --watch cliphist store"
      ];

      env = [
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_WEBRENDER,1"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
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
        gaps_in = 2;
        gaps_out = 0;
        border_size = 1;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      render = {
        cm_fs_passthrough = 2;
        cm_auto_hdr = 2;
      };

      decoration = {
        rounding = 4;

        blur = {
          enabled = true;
          size = 6;
          passes = 3;
        };
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      monitor = [
        "eDP-1, 1920x1200@60, 0x0, 1"
        "desc:Iiyama North America PL2770H 0x30393235, 1920x1080@144, 1920x0, 1"
        "desc: BNQ BenQ LCD 89L03574019, 2560x1440@59.95, 3840x0, 1"
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

      workspace = [
        "r[1-4], monitor:eDP-1"
        "r[5-9], monitor:DP-7"
      ];

      layerrule = [
        "blur on, match:namespace ^noctalia"
        "blur_popups on, match:namespace ^noctalia"
        "ignore_alpha 0.3, match:namespace ^noctalia"
        "xray on, match:namespace ^noctalia"
      ];

      windowrule = [
        "idle_inhibit fullscreen, match:fullscreen 1"

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
  };
}
