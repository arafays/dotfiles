return {
	-- Disable conflicting finders
	{ "nvim-telescope/telescope.nvim", enabled = false },
	{ "ibhagwan/fzf-lua", enabled = false },
	{ "nvim-mini/mini.pick", enabled = false },
	{
		"dmtrKovalenko/fff.nvim",
		build = function()
			require("fff.download").download_or_build_binary()
		end,
		opts = {
			debug = {
				enabled = false,
				show_scores = false,
			},
		},
		lazy = false,
		keys = {
			{
				"<leader>ff",
				function()
					require("fff").find_files()
				end,
				desc = "Find Files (FFF)",
			},
			{
				"<leader>fg",
				function()
					require("fff").live_grep()
				end,
				desc = "Live Grep (FFF)",
			},
			-- Override LazyVim defaults
			{
				"<leader><leader>",
				function()
					require("fff").find_files()
				end,
				desc = "Find Files (FFF)",
			},
			{
				"<leader>/",
				function()
					require("fff").live_grep()
				end,
				desc = "Grep (FFF)",
			},
		},
	},
}
