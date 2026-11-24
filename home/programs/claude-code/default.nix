{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
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

  # PermissionRequest hook: asks through Hyprland's own dialog (hyprland-guiutils) instead of only
  # the terminal prompt. Plays a sound + noctalia toast, pins the dialog on every workspace and
  # repeats until answered; "Deny & discuss" denies with an interrupt and focuses the terminal
  # hosting the session. No answer in time prints nothing, so the terminal prompt takes over.
  # hyprctl and noctalia come from the session PATH (they must match the running compositor/shell).
  # Errexit/pipefail are off on purpose: the script relies on `head` closing pipes and on a hook
  # that must always exit 0.
  permissionPrompt = pkgs.writeShellApplication {
    name = "claude-permission-prompt";
    bashOptions = [ ];
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.procps
      pkgs.pipewire
      pkgs-unstable.hyprland-guiutils
    ];
    text =
      builtins.replaceStrings
        [ "@sound@" ]
        [ "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga" ]
        (builtins.readFile ./permission-prompt.sh);
  };

  # Where the nerv-magi mod is linked, at a path that stays put across rebuilds (the store path
  # behind it changes with the mod's contents). It is both a plugin and the folder of the
  # marketplace that lists it, so Claude Code loads it in place and never writes into it.
  modLink = ".claude/eva-mods/nerv-magi";

  # Keys merged into ~/.claude/settings.json at activation: the look, and the mod's wiring.
  patch = (pkgs.formats.json { }).generate "claude-settings-patch.json" {
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

    # Replaces the built-in tips, so each one is a real Claude Code tip in NERV voice.
    spinnerTipsOverride = {
      label = "NERV";
      excludeDefault = true;
      tips = [
        "Sync ratio dropping? /compact trims the context before the entry plug overflows."
        "Say ultrathink in a prompt to order a deeper MAGI deliberation."
        "/effort sets the reasoning effort mid-session. Raise the sync ratio when it matters."
        "Prefix a line with ! to run a shell command straight from the cage."
        "Ctrl+O expands the transcript. Review the logs before the next sortie."
        "/rename names the session so the MAGI can find it again."
        "/usage shows how much of the A.T. Field is left."
        "/recap sums up where the session stands after you step away."
        "Esc aborts the sortie."
      ];
    };

    # One is picked at random at each startup.
    companyAnnouncements = [
      "NERV Command: all systems nominal. Sortie authorized."
      "MAGI online. Casper, Balthasar and Melchior have reached consensus."
      "Entry plug sealed. Starting synchronization."
      "I mustn't run away."
      "The Geofront is secure. Begin work."
      "Pattern blue not detected. Proceed."
    ];

    # The nerv-magi mod: a marketplace that is a folder, and the plugin it lists switched on.
    # Claude Code registers the marketplace in the background at the first session start after a
    # switch, so that session may ask for /reload-plugins before the mod appears.
    extraKnownMarketplaces.eva.source = {
      source = "directory";
      path = "${config.home.homeDirectory}/${modLink}";
    };
    enabledPlugins."nerv-magi@eva" = true;

    # Timeout > the script's own 120s so it can fall back to the terminal prompt itself.
    # Arrays are replaced by the merge below, so this owns hooks.PermissionRequest entirely.
    hooks.PermissionRequest = [
      {
        hooks = [
          {
            type = "command";
            command = lib.getExe permissionPrompt;
            timeout = 150;
          }
        ];
      }
    ];
  };
in
{
  # Evangelion themes, picked with /theme. The files are read-only here, edit the *-theme.json
  # sources instead. eva is the active one (see `theme` above).
  home.file.".claude/themes/eva.json".source = ./eva-theme.json;
  home.file.".claude/themes/eva-00.json".source = ./eva-00-theme.json;
  home.file.".claude/themes/eva-02.json".source = ./eva-02-theme.json;

  # The nerv-magi mod (mods/nerv-magi): the /magi pane with its battlefield, the tool-call tally
  # band and the NERV wording. Edit it there, rebuild, then /reload-plugins in a running session.
  home.file.${modLink}.source = ./mods/nerv-magi;

  # settings.json also holds state Claude Code and its plugins write to (enabled plugins,
  # permissions, model...), so it can't be a read-only store symlink. Merge only the keys
  # above and leave the rest untouched: objects merge key by key, so other marketplaces and
  # plugins stay. Nix wins on these keys at every switch.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [ ! -e "$settings" ]; then
      run sh -c 'echo "{}" > "$1"' _ "$settings"
    fi
    if [ -f "$settings" ] && [ ! -L "$settings" ]; then
      merged=$(${lib.getExe pkgs.jq} --slurpfile patch ${patch} '. * $patch[0]' "$settings")
      run sh -c 'printf "%s\n" "$1" > "$2"' _ "$merged" "$settings"
    else
      echo "claudeSettings: $settings is a symlink, skipping merge" >&2
    fi
  '';
}
