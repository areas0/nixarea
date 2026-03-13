{ pkgs, ... }:
{
  imports = [ ../../modules/bluetooth.nix ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
    configurationLimit = 1;

    splashImage = ../../assets/xenoblade.jpg;
    default = "saved";
  };

  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "areas-thinkpad";

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = [
      pkgs.mesa.drivers
      pkgs.amdvlk
    ];
  };

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  networking.networkmanager.enable = true;

  system.stateVersion = "24.05";
}
