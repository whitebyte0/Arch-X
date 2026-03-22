require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Window navigation with Ctrl+Arrows
map("n", "<C-Left>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-Right>", "<C-w>l", { desc = "Move to right window" })
map("n", "<C-Down>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-Up>", "<C-w>k", { desc = "Move to top window" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
