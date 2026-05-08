{ additionalConfig, ... }:
let
  v5 = (additionalConfig.noctaliaVersion or "v4") == "v5";
in
{
  imports = [
    ./hypridle
    ./hyprland
    ./hyprlock
    (if v5 then ./noctalia-v5 else ./noctalia)
    ./hyprsunset
  ];
}
