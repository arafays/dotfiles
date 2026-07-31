return {
	-- {
	--   "crusoexia/vim-monokai",
	--   priority = 1000, -- ensure it loads before LazyVim
	--   lazy = false,
	-- },
	{
		"folke/tokyonight.nvim",
		opts = {
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
		},
	},
}

-- To live preview and switch themes, use :Telescope colorscheme
-- You can also map it to a key in your user config, e.g.:
-- vim.keymap.set("n", "<leader>ut", "<cmd>Telescope colorscheme<cr>", { desc = "Change Colorscheme" })
