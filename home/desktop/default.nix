{ additionalConfig, lib, ... }:
let
  v5 = (additionalConfig.noctaliaVersion or "v4") == "v5";
  niri = additionalConfig.enableNiri or false;
in
{
  imports = [
    ./hypridle
    ./hyprland
    ./hyprlock
    (if v5 then ./noctalia-v5 else ./noctalia)
  ]
  ++ lib.optionals niri [ ./niri ]
  # hyprsunset speaks the Hyprland-only CTM protocol and does nothing under
  # niri; on niri-enabled hosts night light comes from noctalia's [nightlight]
  # instead (works in both sessions).
  ++ lib.optionals (!niri) [ ./hyprsunset ];
}
