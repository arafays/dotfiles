-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

vim.g.lazyvim_eslint_auto_format = false

-- Node's provider detector only checks global npm roots. Point at the actual JS
-- entrypoint, supporting both mise's embedded and npm prefix installation layouts.
for _, relative in ipairs({
	"node_modules/neovim/bin/cli.js",
	"lib/node_modules/neovim/bin/cli.js",
}) do
	local host = vim.fn.expand("~/.local/share/mise/installs/npm-neovim/latest/" .. relative)
	if vim.fn.filereadable(host) == 1 then
		vim.g.node_host_prog = host
		break
	end
end

vim.opt.background = "dark" -- set this to dark or light
