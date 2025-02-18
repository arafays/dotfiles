-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- better exit insert mode
map("i", "jk", "<Esc>", { noremap = true, silent = true })
map("i", "jj", "<Esc>", { noremap = true, silent = true })

-- center cursor when moving up and down
map("n", "<C-u>", 'v:count ? "<C-u>" : "<C-u>zz"', { expr = true, noremap = true, silent = true })
map("n", "<C-d>", 'v:count ? "<C-d>" : "<C-d>zz"', { expr = true, noremap = true, silent = true })
