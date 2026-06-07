-- Merged into the lazy.nvim spec via programs.nvchad.extraPlugins.
-- These specs augment NvChad's own (lazy merges specs by plugin name).
return {
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        nix = { "nixfmt" }, -- nixfmt-rfc-style, matches `nix fmt`
        lua = { "stylua" },
        python = { "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        go = { "goimports", "gofmt" },
        yaml = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        markdown = { "prettierd" },
        css = { "prettierd" },
        html = { "prettierd" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "vimdoc",
        "lua",
        "nix",
        "bash",
        "python",
        "dockerfile",
        "yaml",
        "json",
        "go",
        "gomod",
        "typescript",
        "tsx",
        "javascript",
        "html",
        "css",
        "markdown",
        "markdown_inline",
        "helm",
      },
    },
  },
}
