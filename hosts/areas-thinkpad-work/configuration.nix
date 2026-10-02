{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  imports = [
    ../../modules/docker.nix
    ../../modules/bluetooth.nix
    ../../modules/intel-dock-workarounds.nix
  ];

  nixpkgs.overlays = [
    (import ../../overlays/workspace-one-intelligent-hub.nix)
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-14370851-877b-4e97-b209-9f29f2b01b07".device =
    "/dev/disk/by-uuid/14370851-877b-4e97-b209-9f29f2b01b07";
  networking.hostName = "areas-thinkpad-work";

  # LTS (6.18) rather than linuxPackages_latest. The i915 Type-C / DP-alt
  # hotplug bugs tracked in modules/intel-dock-workarounds.nix are both
  # reported against 7.2.x, which is what linuxPackages_latest resolves to
  # here; 6.18 is the series aquamarine#353 calls out as stable for this
  # class of failure. Revisit once those issues are fixed upstream.
  boot.kernelPackages = pkgs.linuxPackages;

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

  environment.systemPackages = [
    pkgs.workspaceone-intelligent-hub
  ];

  system.services.ws1-hub = {
    imports = [ pkgs.workspaceone-intelligent-hub.passthru.services.default ];
  };

  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${lib.getExe pkgs.bash}"
  ];

  security.pki.certificateFiles = [
    "${pkgs.workspaceone-intelligent-hub}/etc/ssl/certs/omnissa-cert.pem"
  ];

  environment.etc.ws1-hub = {
    target = "ws1-hub.conf";
    source = "${pkgs.workspaceone-intelligent-hub}/etc/ws1-hub.conf";
  };

  systemd.tmpfiles.settings.ws1-hub = {
    "/var/lib/ws1-hub".v = {
      group = "root";
      user = "root";
      mode = "755";
    };
    "/var/lib/ws1-hub/agent"."L+".argument = "${pkgs.workspaceone-intelligent-hub}/libexec/agent";
    "/var/lib/ws1-hub/data".v = {
      group = "root";
      user = "root";
      mode = "600";
    };
    "/var/run/ws1-hub".v = {
      group = "root";
      user = "root";
      mode = "700";
    };
    "/var/log/ws1-hub".v = {
      group = "root";
      user = "root";
      mode = "755";
    };
    "/var/opt/omnissa/ws1-hub".v = {
      group = "root";
      user = "root";
      mode = "744";
    };
  };

  system.stateVersion = "24.05";
}
