return {
	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			opts.formatters_by_ft.svelte = { "biome" }
			-- kdlfmt + niri-style collapse (NiriConfigFormatter), deployed by chezmoi
			opts.formatters["kdlfmt-niri"] = {
				command = vim.fn.expand("~/.local/bin/kdlfmt-niri"),
				stdin = true,
			}
			opts.formatters_by_ft.kdl = { "kdlfmt-niri" }
			--- chezmoi tmpl formatter bypass correct formatting
			opts.formatters_by_ft.tmpl = { "prettierd" }
			return opts
		end,
	},
}
