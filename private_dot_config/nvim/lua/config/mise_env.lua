-- Load mise environment variables into Neovim session
-- Runs mise env --json on startup and on :cd

local mise_bin = "mise"
local initial_path = vim.env.PATH
local previous_vars = {}

local function set_previous(data)
  previous_vars = {}
  for var_name, var_value in pairs(data) do
    if var_name ~= "PATH" then
      previous_vars[var_name] = var_value
    end
  end
end

local function get_data()
  local full_command = mise_bin .. " env --json"
  local output = vim.fn.system(full_command)

  -- mise may print warnings like "mise WARN" to stdout
  if string.find(output, "^mise") then
    local first_line = string.match(output, "^[^\n]*")
    vim.notify("[mise] " .. first_line, vim.log.levels.WARN)
    return nil
  end

  local ok, data = pcall(vim.json.decode, output)
  if not ok or data == nil then
    vim.notify("[mise] Invalid JSON from mise env --json", vim.log.levels.ERROR)
    return nil
  end

  return data
end

local function load_env(data)
  -- Unset previously-loaded mise vars first
  for var_name, _ in pairs(previous_vars) do
    vim.env[var_name] = nil
  end

  -- Apply new vars
  for var_name, var_value in pairs(data) do
    vim.env[var_name] = var_value
  end

  set_previous(data)
end

local function dir_changed()
  vim.env.PATH = initial_path
  local data = get_data()
  if data == nil then
    return
  end
  load_env(data)
end

-- Initial load
if vim.fn.executable(mise_bin) == 1 then
  local data = get_data()
  if data then
    vim.env.PATH = initial_path
    load_env(data)
  end
else
  vim.notify("[mise] executable not found", vim.log.levels.WARN)
end

-- Re-run on global directory changes
local group = vim.api.nvim_create_augroup("mise-env", { clear = true })
vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  desc = "Reload mise env on directory change",
  callback = function()
    if vim.v.event.scope == "global" then
      dir_changed()
    end
  end,
})

-- :Mise command to inspect current mise env
vim.api.nvim_create_user_command("Mise", function()
  local data = get_data()
  if data then
    vim.notify(vim.inspect(data), vim.log.levels.INFO)
  end
end, { desc = "Show mise environment variables" })
