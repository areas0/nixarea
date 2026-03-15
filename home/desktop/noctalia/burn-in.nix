{ pkgs, ... }:
let
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
    Unit.Description = "Periodically toggle Noctalia bar position";
    Timer = {
      OnActiveSec = "30m";
      OnUnitActiveSec = "30m";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
