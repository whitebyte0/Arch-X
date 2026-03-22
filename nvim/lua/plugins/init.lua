return {
  -- ── Formatter ─────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- ── LSP ───────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- ── Mason (LSP/formatter/linter installer) ────────
  {
    "williamboman/mason.nvim",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim", "nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "gopls",
        "rust_analyzer",
        "ts_ls",
        "intelephense",
        "html",
        "cssls",
        "jsonls",
        "bashls",
        "yamlls",
        "dockerls",
      },
      automatic_installation = true,
    },
  },

  -- ── Completion ────────────────────────────────────
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- ── Treesitter (syntax highlighting) ──────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc",
        "go", "gomod", "gosum",
        "rust",
        "javascript", "typescript", "tsx",
        "php",
        "html", "css", "json", "yaml", "toml",
        "bash", "dockerfile",
        "markdown", "markdown_inline",
        "python",
        "sql",
        "gitcommit", "diff",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- ── Markdown rendering ────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },

  -- ── TODO comments ─────────────────────────────────
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- ── Trouble (diagnostics panel) ───────────────────
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  -- ── Which-key (keybinding hints) ──────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- ── Autopairs ─────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- ── Git signs in gutter ───────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    opts = {},
  },

  -- ── Surround (cs, ds, ys motions) ─────────────────
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- ── Comment toggle (gcc, gc) ──────────────────────
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    opts = {},
  },
}