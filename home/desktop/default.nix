{ additionalConfig, lib, ... }:
let
  niri = additionalConfig.enableNiri or false;
in
{
  imports = [
    ./hyprland
    ./noctalia-v5
  ]
  ++ lib.optionals niri [ ./niri ]
  # hyprsunset speaks the Hyprland-only CTM protocol and does nothing under
  # niri; on niri-enabled hosts night light comes from noctalia's [nightlight]
  # instead (works in both sessions).
  ++ lib.optionals (!niri) [ ./hyprsunset ];
}
