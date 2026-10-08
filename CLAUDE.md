# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal multi-host NixOS flake. Three hosts share a common base and diverge via a single `additionalConfig` attrset:

- `areas-thinkpad-work` — work laptop (work theme, no gaming packages)
- `areas-thinkpad-home` — personal laptop (personal theme)
- `areas-workstation` — desktop (personal theme, gaming/Star Citizen, docker)

All are `x86_64-linux`.

## Commands

Rebuild the current host (note the flake attribute must match `hostname`):

```
sudo nixos-rebuild switch --flake .#<hostname>
```

Build-only (no switch) for a specific host, useful when iterating without root:

```
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

Formatter — `nix fmt` runs `nixfmt` on the whole tree. All `.nix` files must pass this to commit.

Dev shell — `nix develop` activates the `git-hooks.nix` pre-commit hook. There is no other tooling in the shell.

Flake checks (runs the pre-commit hook set over the tree):

```
nix flake check
```

Preview matugen themes against a wallpaper (installed into the user env as `matugen-preview`; source in `scripts/matugen-preview`):

```
matugen-preview <wallpaper> [scheme-type|all] [contrast] [lightness-dark]
```

## Architecture

### `flake.nix` → `lib/mkHost.nix` → host

`flake.nix` defines two per-host attrsets — `workConfig` and `personalConfig` — carrying `wallpaper`, `theme`, `isLaptop`, `additionalPackages`. Each host calls `mkHost { hostConfig; hardwareConfig; additionalConfig; extraSpecialArgs?; extraModules?; }`.

`lib/mkHost.nix` assembles the `nixosSystem`:

1. Imports `hosts/configuration.nix` (shared NixOS config: Hyprland, pipewire, fonts, fr/en locale, zsh, `areas` user, firewall, networking).
2. Imports the host's own `configuration.nix` + `hardware-configuration.nix`.
3. Wires `stylix` with `additionalConfig.wallpaper` as the image and a base16 scheme produced by `lib/matugen.nix` from that same wallpaper.
4. Wires `home-manager` with `home/` as the user module and passes `pkgs`, `pkgs-unstable`, `nvchad4nix`, `zen`, `claude-code`, and `additionalConfig` via `home-manager.extraSpecialArgs`. `sharedModules` pulls in the zen-browser and noctalia home modules.
5. `home-manager.backupFileExtension = "backup"` — conflicting files get renamed rather than blocking activation.

### Theming pipeline

Wallpaper → `lib/matugen.nix` (build-time `runCommand` invoking the `matugen` CLI) → JSON colors → base16 attrset (mapping Material You tokens to `base00`–`base0F`, with optional `amoled` forcing `base00 = 000000`) → `stylix.base16Scheme` → every stylix-aware app.

Per-host theme knobs live in `flake.nix` (`defaultTheme`, `personalConfig.theme`): `schemeType`, `contrast`, `lightnessDark`, `amoled`. `stylix.polarity = "dark"` is hard-set in `hosts/configuration.nix`.

At the user level, `home/home.nix` wraps `matugen` in a shell script that injects `--source-color-index 0` when missing, so runtime consumers match the build-time scheme.

### Home-manager layout (`home/`)

`home/default.nix` imports `home.nix` (packages + session vars + mime) plus four category directories: `programs/`, `desktop/`, `editor/`, `shell/`. Each category has its own `default.nix` that enumerates the modules it imports.

Note: `home/desktop/hyprland/hyprland.lua` is the whole Hyprland runtime config (Hyprland loads it instead of `hyprland.conf`); `settings.nix` only enables the home-manager module. Idle, lock, night light and the launcher are handled by noctalia, so there are no hypridle/hyprlock/hyprpaper/hyprpanel/walker modules. `niri` is imported only when `additionalConfig.enableNiri` is set, and `hyprsunset` only when it isn't.

`home/desktop/noctalia-v5` is the only noctalia module (the legacy v4 shell and its `noctalia`/`noctalia-qs` flake inputs have been removed) and is imported unconditionally for every host. It's a complete rewrite of the old shell — no Quickshell, no home-manager module from upstream, configuration is a TOML file generated via `pkgs.formats.toml` and dropped at `~/.config/noctalia/config.toml`. The `noctalia-v5` flake input tracks noctalia-shell's default branch directly (no tag pin) — `nix flake update noctalia-v5` picks up whatever is at HEAD.

### Mixing stable and unstable nixpkgs

`pkgs-unstable` is threaded through `specialArgs` (NixOS) and `home-manager.extraSpecialArgs`. Use `pkgs-unstable.<pkg>` only when the stable channel lags; otherwise prefer `pkgs`. Existing examples: Hyprland packages, matugen, kubectl and k8s tooling, terraform, zen, gamescope.

### Overlays

- `overlays/teleport.nix` — pins `teleport_15` from the `nixpkgs_teleport_14` flake input (a specific nixpkgs revision), because the current channel's teleport is incompatible with the server.
- `overlays/fladder.nix` — packages the Fladder Jellyfin client from upstream GitHub release zip with `autoPatchelfHook`; bump `version` + both `sha256` fields together.

## Commit and pre-commit

`.pre-commit-config.yaml` is a **symlink into `/nix/store`** generated by `git-hooks.nix` via `nix develop`. Never edit it directly — change the hook set in `flake.nix` under `checks.<system>.pre-commit.hooks` and re-enter the shell.

Active hooks:
- `nixfmt` on `*.nix` (pre-commit stage)
- `commitizen` on commit messages (commit-msg stage) — **commits must follow Conventional Commits**. Prefixes actually in use: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, and **`bump:`** (project-specific, used for flake.lock updates and dependency bumps — prefer it over `chore:` for those).

## Guidelines

### Adding a package

- Default to `pkgs.<name>`. Use `pkgs-unstable.<name>` **only** when the stable channel lags the feature/version you need; leave a trail in the commit message when you do.
- User-level → add to `home/home.nix` under the appropriate category comment (`# DevOps / Cloud`, `# Kubernetes`, `# CLI tools`, etc.). Don't invent new category headers unless the package truly doesn't fit.
- System-wide (needs root, systemd service, setuid, kernel module, etc.) → add to `hosts/configuration.nix` `environment.systemPackages` or the relevant module.
- Gaming-only packages for the workstation → `extraGamingPackages` in `flake.nix`.

### Adding a home-manager module

- Single-file module → `home/<category>/<name>.nix`.
- Multi-file module → `home/<category>/<name>/default.nix` + siblings (see `home/desktop/noctalia/` and `home/desktop/hyprland/` for the pattern).
- Import it from that category's `default.nix`. Categories: `programs/`, `desktop/`, `editor/`, `shell/`. A module is inert until it's imported — don't assume Nix auto-discovers files.

### Adding a NixOS module

- Put it in `modules/<name>.nix`.
- Import from the specific host's `configuration.nix` if it's host-specific; only add to `hosts/configuration.nix` when it applies to every host (rare).

### Adding a host

1. Create `hosts/<name>/configuration.nix` and `hosts/<name>/hardware-configuration.nix` (generate the latter with `nixos-generate-config`).
2. Register it in `flake.nix` `nixosConfigurations` with a `mkHost` call.
3. Pick an `additionalConfig` — reuse `workConfig`/`personalConfig` or define a new one with `wallpaper`, `theme`, `isLaptop`, `additionalPackages`.

### Theme changes

- Edit `defaultTheme`, `workConfig.theme`, or `personalConfig.theme` in `flake.nix` (or the wallpaper path alongside it).
- Preview schemes against the wallpaper with `matugen-preview <wallpaper> all` before committing, then narrow to the chosen scheme to tune `contrast`/`lightness-dark`.

### Custom or version-pinned packages

- Write an overlay in `overlays/<pkg>.nix` and register it in the `pkgs = import nixpkgs { overlays = [ ... ]; }` block of `flake.nix`.
- If the pin needs a specific nixpkgs revision, add a flake input for that revision and reference it in the overlay (see `overlays/teleport.nix`).

### Before committing

- `nix fmt` — formatting is hook-enforced and will block the commit otherwise.
- `nix flake check` if you've touched `flake.nix` or anything that affects evaluation.
- For a risky change, `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel` builds without switching, so you can verify the config evaluates before `nixos-rebuild switch`.
