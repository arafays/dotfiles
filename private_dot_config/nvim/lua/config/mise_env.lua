-- Keep project tools available in terminal and GUI Neovim sessions.
local mise_bin = vim.fn.exepath("mise")
if mise_bin == "" then
	local local_mise = vim.fn.expand("~/.local/bin/mise")
	if vim.fn.executable(local_mise) == 1 then
		mise_bin = local_mise
	end
end

-- Keep the inherited environment as the baseline when leaving a project.
local initial_path = vim.env.PATH
local original_vars = {}

local function restore_env()
	vim.env.PATH = initial_path
	-- Mason can load after this module. Preserve its fallback on later reloads.
	local mason = package.loaded["mason"]
	local settings = package.loaded["mason.settings"]
	if mason and mason.has_setup and settings and settings.current.PATH == "append" then
		local mason_bin = settings.current.install_root_dir .. "/bin"
		if not (":" .. (vim.env.PATH or "") .. ":"):find(":" .. mason_bin .. ":", 1, true) then
			vim.env.PATH = (vim.env.PATH or "") .. ":" .. mason_bin
		end
	end
	for name, original in pairs(original_vars) do
		vim.env[name] = original.value
	end
end

local function load_env()
	if mise_bin == "" then
		return
	end
	restore_env()
	local result = vim.system({ mise_bin, "env", "--json" }, {
		cwd = vim.fn.getcwd(),
		text = true,
	}):wait()
	if result.code ~= 0 then
		vim.notify("[mise] Could not load this directory's environment; run mise doctor", vim.log.levels.WARN)
		return
	end
	local ok, data = pcall(vim.json.decode, result.stdout or "")
	if not ok or type(data) ~= "table" then
		vim.notify("[mise] Invalid environment JSON", vim.log.levels.ERROR)
		return
	end
	for name, value in pairs(data) do
		if type(value) == "string" then
			if name ~= "PATH" and original_vars[name] == nil then
				-- A table records unset values too, so leaving a project restores them.
				original_vars[name] = { value = vim.env[name] }
			end
			vim.env[name] = value
		end
	end
end

load_env()

local group = vim.api.nvim_create_augroup("mise-env", { clear = true })
vim.api.nvim_create_autocmd("DirChanged", {
	group = group,
	desc = "Reload mise environment on directory change",
	callback = function()
		if vim.v.event.scope == "global" then
			load_env()
		end
	end,
})

vim.api.nvim_create_user_command("Mise", function()
	load_env()
	local tools = {}
	for _, tool in ipairs({ "node", "nvim", "biome", "prettier", "markdownlint-cli2", "tsc" }) do
		tools[#tools + 1] = tool .. ": " .. vim.fn.exepath(tool)
	end
	vim.notify(table.concat(tools, "\n"), vim.log.levels.INFO)
end, { desc = "Reload mise and show tool paths" })
