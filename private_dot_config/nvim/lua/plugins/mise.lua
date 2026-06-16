return {
	{
		"nvim-treesitter/nvim-treesitter",
		init = function()
			require("vim.treesitter.query").add_predicate("is-mise?", function(_, _, bufnr, _)
				local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0):gsub("\\", "/")
				local filename = vim.fn.fnamemodify(filepath, ":t")
				-- Match *mise*.toml filenames (mise.toml, .mise.toml, mise.local.toml, mise.<env>.toml, ...)
				if string.match(filename, ".*mise.*%.toml$") then
					return true
				end
				-- Match .toml files inside mise config directories
				-- (.config/mise/*.toml, .mise/*.toml, etc/mise/*.toml, mise/*.toml, conf.d/*.toml)
				return string.match(filepath, "[\\/]%.?mise[\\/]") ~= nil and string.match(filename, "%.toml$") ~= nil
			end, { force = true, all = false })
		end,
	},
	{
		"jmbuhr/otter.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "toml" },
				group = vim.api.nvim_create_augroup("EmbedToml", {}),
				callback = function()
					require("otter").activate()
				end,
			})
		end,
	}
}
