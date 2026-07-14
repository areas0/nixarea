# notion-app

Official Notion desktop app, built from Notion's Windows installer and run under
nixpkgs' `electron` (native Wayland). Vendored from tsrk's `nix-flex`:

  https://codeberg.org/tsrk/nix-flex (pkgs/applications/productivity/notion-app)

Licensed MIT (see the per-file copyright headers). Kept here verbatim so we can
pin the Electron version ourselves — native Wayland under a chosen Electron
avoids the windowed-resize regression that the prebuilt AppImage hit. See
[[electron-hyprland-resize]].

## Bumping the Notion version

1. Set `version` in `default.nix` and `notion-bin.nix`.
2. Update the `.exe` `hash` in `notion-bin.nix` (`nix-prefetch-url` the new URL).
3. The `sed` patches target Notion's *minified* `.webpack/main/index.js` — they
   may need re-deriving if the bundle changed.
4. `better-sqlite3` / `bufferutil` versions + their `npmDepsHash` may need a bump
   to match what the new Notion expects.
