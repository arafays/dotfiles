-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local opts = { noremap = true, silent = true }
local map = vim.keymap.set
-- better exit insert mode
map("i", "jk", "<Esc>", opts)
map("i", "jj", "<Esc>", opts)

-- to the middle when pressing ctrl + u
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "<C-d>", "<C-d>zz", opts)

--INFO: find and center
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- Git identity switching
map("n", "<leader>gi", "<cmd>GitIdentity<cr>", { desc = "Switch Git Identity", noremap = true, silent = true })
