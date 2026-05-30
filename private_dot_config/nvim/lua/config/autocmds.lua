vim.api.nvim_create_autocmd("FileType", {
	pattern = "gotmpl",
	group = vim.api.nvim_create_augroup("gotmpl_highlight", { clear = true }),
	callback = function(args)
		local filename = vim.api.nvim_buf_get_name(args.buf)
		local basename = vim.fn.fnamemodify(filename, ":t")
		local host_syntax
		if basename:match("gitconfig") then
			host_syntax = "gitconfig"
		elseif basename:match("tmux%.conf") then
			host_syntax = "tmux"
		else
			local host_ext = basename:match(".-%.(.-)%.tmpl$")
			if host_ext then
				local ft_map = {
					conf = "dosini",
					json = "json",
					toml = "toml",
					yml = "yaml",
					yaml = "yaml",
					sh = "bash",
					kdl = "kdl",
					html = "html",
					md = "markdown",
				}
				host_syntax = ft_map[host_ext] or host_ext
			end
		end
		vim.schedule(function()
			vim.treesitter.start(args.buf, "gotmpl")
			if host_syntax then
				vim.bo[args.buf].syntax = host_syntax
			end
		end)
	end,
})