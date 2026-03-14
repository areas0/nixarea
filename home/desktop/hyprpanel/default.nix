{ pkgs, pkgs-unstable, additionalConfig, ... }:
let
  toggleBarPosition = pkgs.writeShellScript "toggle-bar-position" ''
    # Only toggle if the Odyssey OLED is connected
    ODYSSEY_CONNECTED=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq '[.[] | select(.description | test("Odyssey"))] | length')
    if [ "$ODYSSEY_CONNECTED" -eq 0 ]; then
      exit 0
    fi

    # Skip if any window is currently fullscreen
    FULLSCREEN_COUNT=$(hyprctl clients -j | ${pkgs.jq}/bin/jq '[.[] | select(.fullscreen != 0)] | length')
    if [ "$FULLSCREEN_COUNT" -gt 0 ]; then
      exit 0
    fi

    CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/hyprpanel/config.json"
    STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/hyprpanel-bar-position"

    CURRENT="top"
    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(cat "$STATE_FILE")
    fi

    if [ "$CURRENT" = "top" ]; then
      NEXT="bottom"
    else
      NEXT="top"
    fi

    # If config is a symlink (Nix store), replace with a writable copy
    if [ -L "$CONFIG" ]; then
      cp --remove-destination "$(readlink -f "$CONFIG")" "$CONFIG"
      chmod u+w "$CONFIG"
    fi

    ${pkgs.jq}/bin/jq --arg loc "$NEXT" '."theme.bar.location" = $loc' "$CONFIG" > "$CONFIG.tmp" \
      && mv -f "$CONFIG.tmp" "$CONFIG"

    hyprpanel restart
    echo "$NEXT" > "$STATE_FILE"
  '';
in
{
  programs.hyprpanel = {
    enable = true;

    package = pkgs-unstable.hyprpanel;
    # Configure and theme almost all options from the GUI.
    # See 'https://hyprpanel.com/configuration/settings.html'.
    # Default: <same as gui>
    settings = {

      # Configure bar layouts for monitors.
      # See 'https://hyprpanel.com/configuration/panel.html'.
      # Default: null
      layout = {
        bar.layouts = {
          "0" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [ "media" ];
            right = [
              "volume"
              "systray"
              "notifications"
            ];
          };
        };
      };

      wallpaper = {
        enable = true;
        image = "${additionalConfig.wallpaper}";
      };

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = false;
      bar.workspaces.show_numbered = true;
      menus.clock = {
        time = {
          military = true;
          hideSeconds = true;
        };
        weather.unit = "metric";
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = true;

      theme.bar.transparent = true;
      theme.bar.location = "top";

      theme.font = {
        name = "CaskaydiaCove NF";
        size = "16px";
      };

      theme.bar.buttons.style = "split";
    };
  };

  systemd.user.services.hyprpanel-toggle-position = {
    Unit = {
      Description = "Toggle HyprPanel bar position for burn-in prevention";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${toggleBarPosition}";
    };
  };

  systemd.user.timers.hyprpanel-toggle-position = {
    Unit = {
      Description = "Periodically toggle HyprPanel bar position";
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
