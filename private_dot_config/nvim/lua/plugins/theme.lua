return {
	{
		"nyoom-engineering/oxocarbon.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			vim.opt.background = "dark"
			vim.cmd.colorscheme "oxocarbon"

			-- Transparency: clear backgrounds
			local transparent_groups = {
				"Normal", "NormalFloat", "NormalNC",
				"SignColumn", "LineNr", "FoldColumn",
				"CursorLineNr", "FloatBorder",
				"TelescopeNormal", "TelescopeBorder",
				"NvimTreeNormal", "NvimTreeEndOfBuffer",
				"WhichKeyFloat", "MsgArea",
			}
			for _, group in ipairs(transparent_groups) do
				vim.api.nvim_set_hl(0, group, { bg = "none" })
			end
		end,
	},
	-- {
	--   "crusoexia/vim-monokai",
	--   priority = 1000, -- ensure it loads before LazyVim
	--   lazy = false,
	-- },
}

-- To live preview and switch themes, use :Telescope colorscheme
-- You can also map it to a key in your user config, e.g.:
-- vim.keymap.set("n", "<leader>ut", "<cmd>Telescope colorscheme<cr>", { desc = "Change Colorscheme" })
