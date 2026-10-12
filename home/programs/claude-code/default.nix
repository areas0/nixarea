{ lib, pkgs, ... }:
let
  # Wrapped so jq/git resolve from the store, not from whatever PATH Claude Code runs with.
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline-eva";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
    ];
    text = builtins.readFile ./statusline.sh;
  };

  # Appearance keys merged into ~/.claude/settings.json at activation.
  appearance = (pkgs.formats.json { }).generate "claude-appearance.json" {
    theme = "custom:eva";
    statusLine = {
      type = "command";
      command = lib.getExe statusline;
      padding = 1;
    };
    spinnerVerbs = {
      mode = "replace";
      verbs = [
        "Synchronizing with Unit-01"
        "Raising the AT Field"
        "Consulting the MAGI"
        "Detecting pattern blue"
        "Calibrating the entry plug"
        "Pressurizing LCL"
        "Awaiting Commander Ikari's orders"
        "Running the Dummy System"
        "Sortie from Cage 7"
        "Computing sync ratio"
        "Evacuating to Geofront"
        "Not running away"
      ];
    };
  };
in
{
  # Evangelion theme. The theme file is read-only here, edit eva-theme.json instead.
  home.file.".claude/themes/eva.json".source = ./eva-theme.json;

  # settings.json also holds state Claude Code and its plugins write to (enabled plugins,
  # permissions, model...), so it can't be a read-only store symlink. Merge only the
  # appearance keys above and leave the rest untouched. Nix wins on these keys at every switch.
  home.activation.claudeAppearance = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [ ! -e "$settings" ]; then
      run sh -c 'echo "{}" > "$1"' _ "$settings"
    fi
    if [ -f "$settings" ] && [ ! -L "$settings" ]; then
      merged=$(${lib.getExe pkgs.jq} --slurpfile patch ${appearance} '. * $patch[0]' "$settings")
      run sh -c 'printf "%s\n" "$1" > "$2"' _ "$merged" "$settings"
    else
      echo "claudeAppearance: $settings is a symlink, skipping merge" >&2
    fi
  '';
}
