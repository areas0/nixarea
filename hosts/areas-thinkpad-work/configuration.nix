# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ../../modules/bluetooth.nix
      ../../modules/docker.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-42ec07de-819a-4d15-a3e5-08663f384a75".device = "/dev/disk/by-uuid/42ec07de-819a-4d15-a3e5-08663f384a75";
  networking.hostName = "areas-thinkpad"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  systemd.services = {
    pritunl-client-service = {
      description = "Pritunl Client Daemon";
      script = "${pkgs-unstable.pritunl-client}/bin/pritunl-client-service";
      wantedBy = [ "multi-user.target" ];
    };
  };

  virtualisation = {
    podman = {
      enable = true;
    };
  };
}
