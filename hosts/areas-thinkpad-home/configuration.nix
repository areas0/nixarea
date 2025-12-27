{ pkgs, ... }:
{
  imports = [ ../../modules/bluetooth.nix ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Bootloader.
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

  networking.hostName = "areas-thinkpad"; # Define your hostname.

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
