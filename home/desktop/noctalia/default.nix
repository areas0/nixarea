{
  pkgs,
  config,
  lib,
  additionalConfig,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
  isLaptop = additionalConfig.isLaptop or false;

  officialPlugins = "https://github.com/noctalia-dev/noctalia-plugins";

  toggleBarPosition = pkgs.writeShellScript "toggle-bar-position" ''
    ODYSSEY_CONNECTED=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.description | test("Odyssey"))] | length')
    if [ "$ODYSSEY_CONNECTED" -eq 0 ]; then
      exit 0
    fi

    FULLSCREEN_COUNT=$(hyprctl clients -j | ${pkgs.jq}/bin/jq '[.[] | select(.fullscreen != 0)] | length')
    if [ "$FULLSCREEN_COUNT" -gt 0 ]; then
      exit 0
    fi

    CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.json"
    STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/noctalia-bar-position"

    CURRENT="top"
    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(cat "$STATE_FILE")
    fi

    if [ "$CURRENT" = "top" ]; then
      NEXT="bottom"
    else
      NEXT="top"
    fi

    if [ -L "$CONFIG" ]; then
      cp --remove-destination "$(readlink -f "$CONFIG")" "$CONFIG"
      chmod u+w "$CONFIG"
    fi

    ${pkgs.jq}/bin/jq --arg pos "$NEXT" '.bar.position = $pos' "$CONFIG" > "$CONFIG.tmp" \
      && mv -f "$CONFIG.tmp" "$CONFIG"

    noctalia-shell ipc call state reload
    echo "$NEXT" > "$STATE_FILE"
  '';
in
{
  programs.noctalia-shell = {
    enable = true;

    # Stylix handles base colors, but its default maps mPrimary = mSecondary = base05.
    # Override with distinct Material You colors from the matugen base16 scheme.
    colors = {
      mPrimary = lib.mkForce c.base0D;
      mSecondary = lib.mkForce c.base0A;
      mTertiary = lib.mkForce c.base0E;
      mOnSurfaceVariant = lib.mkForce c.base04;
      mOutline = lib.mkForce c.base03;
      mHover = lib.mkForce c.base02;
    };

    settings = {
      bar = {
        position = "top";
        density = "spacious";
        fontScale = 1.2;
        floating = true;
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "number";
            }
            { id = "SystemMonitor"; }
            { id = "plugin:network-indicator"; }
            { id = "AudioVisualizer"; }
            { id = "ActiveWindow"; }
          ];
          center = [
            { id = "MediaMini"; }
          ];
          right =
            [ { id = "Volume"; } ]
            ++ lib.optionals isLaptop [
              { id = "Brightness"; }
              { id = "Battery"; }
            ]
            ++ [
              { id = "VPN"; }
              { id = "Network"; }
              { id = "Bluetooth"; }
              { id = "plugin:privacy-indicator"; }
              { id = "plugin:openhue"; }
              { id = "Tray"; }
              { id = "NotificationHistory"; }
              {
                id = "Clock";
                formatHorizontal = "HH:mm";
                formatVertical = "HH mm";
                useMonospacedFont = true;
              }
            ];
        };
      };

      wallpaper = {
        enabled = true;
        setWallpaperOnAllMonitors = true;
      };

      appLauncher = {
        enableClipboardHistory = true;
        enableWindowsSearch = true;
        enableSessionSearch = true;
        enableSettingsSearch = true;
        sortByMostUsed = true;
        terminalCommand = "kitty -e";
        viewMode = "list";
      };

      notifications = {
        enabled = true;
        location = "top_right";
      };

      osd = {
        enabled = true;
        location = "top_right";
      };

      location = {
        useFahrenheit = false;
        use12hourFormat = false;
      };

      colorSchemes = {
        useWallpaperColors = false;
      };

      nightLight.enabled = false;
      idle.enabled = false;
    };

    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = officialPlugins;
        }
      ];
      states = {
        privacy-indicator = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
        polkit-agent = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
        keybind-cheatsheet = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
        vscode-provider = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
        file-search = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
        openhue = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
        network-indicator = {
          enabled = true;
          sourceUrl = officialPlugins;
        };
      };
    };
  };

  # Burn-in prevention: toggle bar between top/bottom on Odyssey OLED
  systemd.user.services.noctalia-toggle-position = {
    Unit = {
      Description = "Toggle Noctalia bar position for burn-in prevention";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${toggleBarPosition}";
    };
  };

  systemd.user.timers.noctalia-toggle-position = {
    Unit = {
      Description = "Periodically toggle Noctalia bar position";
    };
    Timer = {
      OnActiveSec = "30m";
      OnUnitActiveSec = "30m";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
