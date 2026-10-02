{ pkgs, ... }:
# Workarounds for two open upstream bugs that wedge the display output on this
# laptop (Meteor Lake / i915 + Hyprland 0.56.2 + aquamarine 0.15.0):
#
#   1. hyprwm/aquamarine#403 — when a USB-C DP-alt monitor is unplugged,
#      aquamarine drops its own state for the connector but never commits the
#      atomic modeset that disables the CRTC. The kernel keeps the connector
#      enabled, i915 holds tc->link_refcount, and the Type-C port stays stuck
#      in TC_PORT_TBT_ALT — so the sink is invisible to the driver on replug
#      and the dock output "works once per boot".
#
#   2. hyprwm/aquamarine#343 / #382 and omacom/omarchy#11909 — a lost page-flip
#      completion around a modeset leaves aquamarine permanently "awaiting" a
#      flip ("drm: Cannot commit when a page-flip is awaiting" in the log). No
#      further frames are committed on ANY output, so every screen goes dead
#      while the kernel, input and VTs stay healthy. Commonly triggered by the
#      DPMS-off/on cycle at the end of an idle timeout.
#
# Both are open with no upstream fix as of 2026-09-15. This module carries the
# two escape hatches plus a recovery tool; it is host-scoped (imported only by
# areas-thinkpad-work) rather than living in hosts/configuration.nix.
let
  display-rescue = pkgs.writeShellScriptBin "display-rescue" ''
    # Recover a wedged Hyprland display session without rebooting.
    # Safe to run from a TTY (Ctrl+Alt+F3) while the screens are dead.
    set -uo pipefail

    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

    # A TTY login does not inherit the compositor's instance signature, so
    # resolve it from the newest socket directory Hyprland left behind.
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      sig=$(ls -1t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
      if [ -z "$sig" ]; then
        echo "no running Hyprland instance under $XDG_RUNTIME_DIR/hypr" >&2
        exit 1
      fi
      export HYPRLAND_INSTANCE_SIGNATURE="$sig"
    fi

    echo "instance: $HYPRLAND_INSTANCE_SIGNATURE"

    echo
    echo "==> kernel connector state"
    for c in /sys/class/drm/card*-*/; do
      printf '    %-18s %-13s %s\n' \
        "$(basename "$c")" "$(cat "$c/status")" "$(cat "$c/enabled")"
    done

    echo
    echo "==> compositor monitor state"
    hyprctl monitors all | grep -E '^Monitor|dpmsStatus'

    echo
    echo "==> recent compositor errors"
    hyprctl rollinglog 2>/dev/null | grep -E 'ERR' | tail -10 || echo "    (none)"

    # Step 1 — a DPMS off/on cycle is enough when the stall is only a lost
    # page-flip completion and the connector itself is still healthy.
    echo
    echo "==> 1/3 DPMS off -> on"
    hyprctl dispatch dpms off
    sleep 3
    hyprctl dispatch dpms on
    sleep 1

    # Step 2 — explicitly disable then re-enable every external output. This
    # issues the CRTC-disabling atomic commit that aquamarine#403 skips, which
    # is what releases i915's tc->link_refcount. `hyprctl keyword` refuses to
    # run against a Lua config ("can't work with non-legacy parsers"), so this
    # goes through `hyprctl eval` and the hl.monitor() Lua binding instead.
    echo
    echo "==> 2/3 cycling external outputs through a real CRTC teardown"
    for out in $(hyprctl -j monitors all | ${pkgs.jq}/bin/jq -r '.[].name' | grep -v '^eDP'); do
      echo "    $out"
      hyprctl eval "hl.monitor({ output = \"$out\", disabled = true })" >/dev/null
      sleep 2
      hyprctl eval "hl.monitor({ output = \"$out\", disabled = false, mode = \"preferred\", position = \"auto\", scale = 1 })" >/dev/null
      sleep 1
    done

    # Step 3 — re-probe every connector and rebuild the renderer.
    echo
    echo "==> 3/3 force renderer reload"
    hyprctl dispatch forcerendererreload
    sleep 2

    echo
    echo "==> result"
    hyprctl monitors | grep -E '^Monitor|[0-9]+x[0-9]+@'

    echo
    echo "Still dark? Then the connector is stuck with its CRTC enabled and i915"
    echo "is still holding tc->link_refcount (aquamarine#403). Only dropping DRM"
    echo "master frees it — switch away from the compositor's VT, WAIT, then back:"
    echo
    echo "    Ctrl+Alt+F3   then count five seconds — the pause is what matters"
    echo "    Ctrl+Alt+F1   (or whichever VT the session is on)"
    echo
    echo "Switching straight back without the pause does not release the reference."
  '';
in
{
  # Force aquamarine onto the legacy (non-atomic) DRM path. The atomic commit
  # path is where both bugs above live; the legacy path is reported to dodge
  # them in aquamarine#394 and #353. Cost: no VRR, no tearing control, and the
  # hardware cursor is less reliable — acceptable on this laptop, which uses
  # none of the three.
  #
  # This has to be in the session environment rather than hl.env() in
  # hyprland.lua: aquamarine reads it when it brings the DRM backend up, which
  # happens before the Lua config's env calls take effect.
  environment.sessionVariables.AQ_NO_ATOMIC = "1";

  environment.systemPackages = [
    display-rescue
    pkgs.usbutils # lsusb — for telling a DP-alt dock apart from a TB4 one
  ];
}
