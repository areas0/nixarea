{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services = {
    blueman.enable = true;

    pipewire.wireplumber.extraConfig."50-bluez-config" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.codecs" = [ "ldac" "aac" "sbc_xq" "sbc" ];
        "bluez5.default.rate" = 96000;
      };
    };

    pipewire.wireplumber.extraConfig."51-bluez-ldac" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            { "device.name" = "~bluez_card.*"; }
          ];
          actions = {
            update-props = {
              "bluez5.a2dp.ldac.quality" = "hq";
            };
          };
        }
      ];
    };
  };
}
