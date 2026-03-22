{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.noctalia-shell;
  noctaliaExe = lib.getExe cfg.package;
  restartScript = pkgs.writeShellScript "noctalia-hm-restart" ''
    set -euo pipefail
    if [[ -n "''${DRY_RUN_CMD:-}" ]]; then
      echo "[dry-run] would restart noctalia-shell"
      exit 0
    fi
    PATH="${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.procps
        pkgs.gnugrep
        pkgs.systemd
      ]
    }''${PATH:+:$PATH}"

    # noctalia-shell is a Qt wrapper → exec's quickshell; comm name is .quickshell-wra
    # Match the quickshell process whose env contains QS_CONFIG_PATH=…noctalia-shell
    pid=""
    for p in $(pgrep -f quickshell -u "$(id -u)"); do
      if [[ -r "/proc/$p/environ" ]] && tr '\0' '\n' < "/proc/$p/environ" | grep -q 'QS_CONFIG_PATH=.*noctalia-shell'; then
        pid="$p"
        break
      fi
    done
    if [[ -z "''${pid:-}" ]] || [[ ! -r "/proc/''${pid}/environ" ]]; then
      exit 0
    fi

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      key="''${line%%=*}"
      case "$key" in
        WAYLAND_DISPLAY|WAYLAND_SOCKET|XDG_RUNTIME_DIR|HYPRLAND_INSTANCE_SIGNATURE|DISPLAY|DBUS_SESSION_BUS_ADDRESS|PATH|HOME|USER|LANG|QT_QPA_PLATFORM|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE)
          export "$line" ;;
      esac
    done < <(tr '\0' '\n' < "/proc/''${pid}/environ")

    kill -TERM "$pid" 2>/dev/null || true
    i=0
    while kill -0 "$pid" 2>/dev/null && [[ $i -lt 40 ]]; do
      sleep 0.05
      i=$((i + 1))
    done

    # Launch in an independent user scope so it survives the HM activation service exiting
    systemd-run --user --scope --unit=noctalia-restart-"$$" "${noctaliaExe}"  >/dev/null 2>&1 &
  '';
in
lib.mkIf cfg.enable {
  # HM types.str: one store ref per line — the activation line is only this path (bash executes it).
  home.activation.restartNoctalia = lib.hm.dag.entryAfter [ "writeBoundary" ] "${restartScript}";
}
