-- Native chezmoi template support for .tmpl source files:
-- - treesitter injection of the target language (gotmpl + target highlighting)
-- - formatting through templates: conform's `chezmoi` formatter masks {{ }}
--   spans, runs the target filetype's formatter (e.g. biome for jsonc), restores
-- - apply-on-save, live preview (:Chezmoi preview), template diagnostics
--
-- Replaces the editing half of the LazyVim `util.chezmoi` extra
-- (alker0/chezmoi.vim compound filetypes + xvzc/chezmoi.nvim watcher).
if true then
	return {}
end

return {
	{ "alker0/chezmoi.vim", enabled = false },
	{ "xvzc/chezmoi.nvim", enabled = false },
	{
		"dpezto/chezmoi-template.nvim",
		lazy = false,
		---@module 'chezmoi-template'
		---@type chezmoi-template.Config
		opts = {},
		keys = {
			{ "<leader>sz", "<cmd>Chezmoi pick<cr>", desc = "Chezmoi" },
		},
	},
	{
		"nvimdev/dashboard-nvim",
		optional = true,
		opts = function(_, opts)
			-- The util.chezmoi extra wired this entry to xvzc/chezmoi.nvim; point it
			-- at chezmoi-template.nvim's picker instead.
			for _, entry in ipairs(opts.config.center or {}) do
				if entry.key == "c" then
					entry.action = "<cmd>Chezmoi pick<cr>"
				end
			end
		end,
	},
	{
		"folke/snacks.nvim",
		optional = true,
		opts = function(_, opts)
			for _, entry in ipairs(opts.dashboard.preset.keys or {}) do
				if entry.key == "c" then
					entry.action = "<cmd>Chezmoi pick<cr>"
				end
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "gotmpl" })
		end,
	},
}
