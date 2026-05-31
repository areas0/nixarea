{ pkgs, ... }:
{
  imports = [ ../../modules/bluetooth.nix ];

  # boot.loader.grub = {
  #   enable = true;
  #   device = "nodev";
  #   useOSProber = true;
  #   efiSupport = true;
  #   configurationLimit = 0;

  #   # splashImage = ../../assets/xenoblade.jpg;
  #   default = "saved";
  # };

  # boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  # system.maxGenerations = 1;

  networking.hostName = "areas-thinkpad-home";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # extraPackages = [ pkgs.amdvlk ];
  };

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  networking.networkmanager.enable = true;

  system.stateVersion = "24.05";
}
