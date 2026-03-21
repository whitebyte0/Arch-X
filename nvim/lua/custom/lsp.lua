-- Setup LSP for Go (gopls)
local nvim_lsp = require('lspconfig')

-- Enable gopls (Go language server)
nvim_lsp.gopls.setup {
  on_attach = function(client, bufnr)
    -- Custom key mappings for LSP features
    local opts = { noremap=true, silent=true }
    -- Go to definition
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    -- Show hover info
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  end,
  flags = {
    debounce_text_changes = 150,
  }
}

