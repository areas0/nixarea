{ ... }:
{
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "areas-thinkpad"; # Define your hostname.
}
