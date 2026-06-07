{
  config,
  lib,
  nvchad4nix,
  pkgs,
  pkgs-unstable,
  matugenScheme,
  ...
}:
{
  imports = [ nvchad4nix.homeManagerModule ];

  # NvChad compiles its theme into a bytecode cache under the data dir, and
  # only rebuilds it via the lazy `build` hook on plugin install/update — never
  # when chadrcConfig changes. Since our theme is wallpaper-derived (it changes
  # whenever matugen re-runs), regenerate the cache on every activation so nvim
  # actually picks up new colors / the transparency flag. Runs after the module's
  # copyNvChad step (chadrc must be in place first); best-effort so a missing
  # binary or not-yet-installed plugins on a fresh machine can't break activation.
  home.activation.regenBase46Cache = lib.hm.dag.entryAfter [ "copyNvChad" ] ''
    nvim_bin="${config.home.profileDirectory}/bin/nvim"
    if [ -x "$nvim_bin" ]; then
      run ${pkgs.coreutils}/bin/timeout 60 "$nvim_bin" --headless \
        "+lua require('base46').load_all_highlights()" +qa > /dev/null 2>&1 || true
    fi
  '';

  programs.nvchad = {
    enable = true;
    neovim = pkgs-unstable.neovim-unwrapped;
    extraPackages = with pkgs; [
      # Language servers
      bash-language-server
      docker-compose-language-service
      dockerfile-language-server
      emmet-language-server
      gopls
      helm-ls
      nixd
      typescript-language-server
      vscode-langservers-extracted # eslint, jsonls, html, cssls
      yaml-language-server
      (python3.withPackages (
        ps: with ps; [
          python-lsp-server
          flake8
        ]
      ))
      # Formatters
      gofumpt
      gotools # goimports
      nixfmt-rfc-style
      prettierd
      ruff
      shfmt
      stylua
    ];
    chadrcConfig = import ./theme.nix { inherit matugenScheme; };
    extraConfig = builtins.readFile ./lua/extra-config.lua;
    extraPlugins = builtins.readFile ./lua/plugins.lua;
    hm-activation = true;
    backup = true;
  };
}
