# Vendored from https://codeberg.org/tsrk/nix-flex
# Original copyright (c) 2026 tsrk. <tsrk@tsrk.me> - MIT
# SPDX-License-Identifier: MIT
{
  lib,
  options,
  config,
  ...
}:

let
  cfg = config.ws1-hub;
in
{
  _class = "service";
  options = {
    ws1-hub = {
      package = lib.options.mkOption {
        description = "Package to use for the Workspace ONE Intelligent Hub Agent";
        type = lib.types.package;
      };
    };
  };

  config = {
    process.argv = [
      "${cfg.package}/bin/ws1HubAgent"
    ];
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.service = {
      after = [ "network.target" ];
      preStop = ''
        ${lib.getExe cfg.package} service --stop
      '';
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
        KillMode = "process";
      };
    };
  };
}
