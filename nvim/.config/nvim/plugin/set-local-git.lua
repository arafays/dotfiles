-- Path to the identities file (adjust as needed)
local identities_file = vim.fn.stdpath("config") .. "/user/git_identities.lua"

-- Load predefined identities; if file missing or malformed, start with an empty table.
local function load_identities()
  local ok, identities = pcall(dofile, identities_file)
  if not ok or type(identities) ~= "table" then
    identities = {}
  end
  return identities
end

-- Serialize and save the identities table back to identities_file.
local function save_identities(identities)
  local file = io.open(identities_file, "w")
  -- try opening the file
  if not file then
    local dir = identities_file:match("(.*/)")
    if dir then
      -- if it fails, try creating the directory
      vim.notify("File not created creating the directory ..", vim.log.levels.INFO)
      os.execute("mkdir -p " .. dir)
      -- create the file
      file = io.open(identities_file, "w")
    end
  end
  -- if it fails, notify the user and return
  if not file then
    vim.notify("Failed to create identities file.", vim.log.levels.ERROR)
    return
  end
  file:write("return {\n")
  for _, id in ipairs(identities) do
    file:write(string.format("  { name = %q, email = %q },\n", id.name, id.email))
  end
  file:write("}\n")
  file:close()
end

-- Set local Git config and update a global variable for statusline.
local function set_git_config(name, email)
  vim.system({ "git", "config", "--local", "user.name", name }, { text = true }):wait()
  vim.system({ "git", "config", "--local", "user.email", email }, { text = true }):wait()
  vim.g.git_identity = name .. " <" .. email .. ">"
end

-- Get git config value using vim.system (0.11 compatible)
local function get_git_config(scope, key)
  local result = vim.system({ "git", "config", "--" .. scope, "--get", key }, { text = true }):wait()
  if result.code == 0 and result.stdout then
    return vim.trim(result.stdout)
  end
  return ""
end

-- Check if in a git repository
local function is_git_repo()
  local result = vim.system({ "git", "rev-parse", "--is-inside-work-tree" }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) == "true"
end

-- Main function: if in a Git repo and local Git identity isn't set, prompt for one.
local function ensure_git_config()
  -- Proceed only if in a git repo
  if not is_git_repo() then
    return
  end

  -- Get current local Git config
  local local_name = get_git_config("local", "user.name")
  local local_email = get_git_config("local", "user.email")

  local global_name = get_git_config("global", "user.name")
  local global_email = get_git_config("global", "user.email")

  if local_name ~= "" and local_email ~= "" then
    -- Set our global variable too, so statusline knows.
    vim.g.git_identity = local_name .. " <" .. local_email .. ">"
    return
  end

  -- Load predefined identities.
  local identities = load_identities()
  local choices = {}
  local global_identity_prompt = "Use global Git user " .. global_name .. " <" .. global_email .. ">"
  local new_identity_prompt = "Add new identity..."

  -- Format the choices with icons for better UI
  local format_item = function(item)
    if item == global_identity_prompt then
      return "  " .. item
    elseif item == new_identity_prompt then
      return "  " .. item
    else
      return "  " .. item
    end
  end

  table.insert(choices, global_identity_prompt)
  table.insert(choices, new_identity_prompt)

  -- Build a list of choices formatted as "Name <email>".
  for _, id in ipairs(identities) do
    table.insert(choices, id.name .. " <" .. id.email .. ">")
  end

  -- Use vim.ui.select with improved formatting
  vim.ui.select(choices, {
    prompt = "Select a Git identity for this repo:",
    format_item = format_item,
    kind = "git-identity",
  }, function(choice)
    if not choice then
      vim.notify("No identity selected. Local Git user remains unset.", vim.log.levels.WARN)
      return
    end

    local selected_identity = nil

    if choice == global_identity_prompt then
      selected_identity = { name = global_name, email = global_email }
      table.insert(identities, selected_identity)
      save_identities(identities)
      set_git_config(selected_identity.name, selected_identity.email)
      vim.notify(
        "Local Git user set to: " .. selected_identity.name .. " <" .. selected_identity.email .. ">",
        vim.log.levels.INFO
      )
    elseif choice == new_identity_prompt then
      -- Prompt for new name.
      vim.ui.input({ prompt = "Enter full name: " }, function(name)
        if not name or name == "" then
          vim.notify("Name cannot be empty.", vim.log.levels.ERROR)
          return
        end
        -- Prompt for new email.
        vim.ui.input({ prompt = "Enter email: " }, function(email)
          if not email or email == "" then
            vim.notify("Email cannot be empty.", vim.log.levels.ERROR)
            return
          end
          selected_identity = { name = name, email = email }
          table.insert(identities, selected_identity)
          save_identities(identities)
          set_git_config(selected_identity.name, selected_identity.email)
          vim.notify(
            "Local Git user set to: " .. selected_identity.name .. " <" .. selected_identity.email .. ">",
            vim.log.levels.INFO
          )
        end)
      end)
    else
      -- Look up the selected identity.
      for _, id in ipairs(identities) do
        if choice == id.name .. " <" .. id.email .. ">" then
          selected_identity = id
          break
        end
      end
      if selected_identity then
        set_git_config(selected_identity.name, selected_identity.email)
        vim.notify(
          "Local Git user set to: " .. selected_identity.name .. " <" .. selected_identity.email .. ">",
          vim.log.levels.INFO
        )
      else
        vim.notify("Selected identity not found.", vim.log.levels.ERROR)
      end
    end
  end)
end

-- Create an autocmd to run when entering a directory
vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
  callback = function()
    ensure_git_config()
  end,
  desc = "Set local git identity when entering a git repository",
})

-- Add a command to manually trigger the identity selection
vim.api.nvim_create_user_command("GitIdentity", function()
  ensure_git_config()
end, {
  desc = "Set local git identity for current repository"
})

-- No return statement here
