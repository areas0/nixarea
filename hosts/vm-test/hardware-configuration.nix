{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    ../../modules/docker.nix
    ../../modules/bluetooth.nix
  ];

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b8b52410-e58d-4a5b-aa11-942d9ca5cc98";
      fsType = "ext4";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.virtualbox.guest.enable = true;

  
  systemd.services = {
    # TODO: enable when pritunl is built
    # pritunl-client-service = {
    #   description = "Pritunl Client Daemon";
    #   script = "${pkgs.unstable.pritunl-client}/bin/pritunl-client-service";
    #   wantedBy = [ "multi-user.target" ];
    # };
  };
}
