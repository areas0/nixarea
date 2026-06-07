-- Loaded at the end of init.lua via programs.nvchad.extraConfig.
-- Kept reproducible here because hm-activation overwrites ~/.config/nvim.

-- ── Editor options ────────────────────────────────────────────────────────
local o = vim.o
o.relativenumber = true
o.cursorline = true
o.scrolloff = 8
o.wrap = false

-- ── Language servers ──────────────────────────────────────────────────────
-- Server binaries are provided by programs.nvchad.extraPackages (see default.nix).
-- Default configs ship with nvim-lspconfig (runtime/lsp/*.lua, nvim >= 0.11).

-- yamlls: scope the kubernetes schema to manifest-looking files only, and pull
-- the rest from SchemaStore so plain yaml isn't mis-validated as k8s.
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
      schemas = {
        kubernetes = { "*.k8s.yaml", "**/k8s/**/*.yaml", "**/manifests/**/*.yaml" },
      },
    },
  },
})

-- gopls: format with gofumpt and organise imports.
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
})

vim.lsp.enable {
  "html",
  "cssls",
  "nixd",
  "bashls",
  "dockerls",
  "docker_compose_language_service",
  "pylsp",
  "yamlls",
  "helm_ls",
  "ts_ls",
  "eslint",
  "jsonls",
  "gopls",
  "emmet_language_server",
}
