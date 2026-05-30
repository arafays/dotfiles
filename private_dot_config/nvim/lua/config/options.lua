-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

vim.opt.background = "dark"

vim.filetype.add({
	extension = {
		tmpl = "gotmpl",
	},
	pattern = {
		[".*/environment%.d/.*%.conf"] = "dosini",
		[".*/environment%.d/.*%.conf%.tmpl"] = "gotmpl",
		[".*/qt5ct/.*%.conf"] = "dosini",
		[".*tmux%.conf$"] = "tmux",
	},
})
