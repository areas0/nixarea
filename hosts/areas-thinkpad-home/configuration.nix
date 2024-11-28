{ pkgs, ... }:
{
  imports = [
    ../../modules/bluetooth.nix
  ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.configurationLimit = 1;

  networking.hostName = "areas-thinkpad"; # Define your hostname.

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = [ pkgs.mesa.drivers pkgs.amdvlk ];
  };

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  networking.networkmanager.enable = true;
}
