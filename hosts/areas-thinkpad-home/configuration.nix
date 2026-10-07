{ ... }:
{
  imports = [ ../../modules/bluetooth.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "areas-thinkpad-home";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  system.stateVersion = "24.05";
}
