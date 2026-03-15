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

    CURRENT=$(noctalia-shell ipc call state all | ${pkgs.jq}/bin/jq -r '.settings.bar.position')
    if [ "$CURRENT" = "top" ]; then
      NEXT="bottom"
    else
      NEXT="top"
    fi

    for SCREEN in $(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name'); do
      noctalia-shell ipc call bar setPosition "$NEXT" "$SCREEN"
    done
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
