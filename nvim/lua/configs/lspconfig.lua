require("nvchad.configs.lspconfig").defaults()

local servers = {
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
}

vim.lsp.enable(servers)