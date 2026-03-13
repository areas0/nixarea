{
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ../../modules/docker.nix
    ../../modules/bluetooth.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-14370851-877b-4e97-b209-9f29f2b01b07".device =
    "/dev/disk/by-uuid/14370851-877b-4e97-b209-9f29f2b01b07";
  networking.hostName = "areas-thinkpad-work";

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

  system.stateVersion = "24.05";
}
