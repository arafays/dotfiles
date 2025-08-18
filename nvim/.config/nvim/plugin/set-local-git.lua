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
    file:write(string.format("  { name = %q, email = %q, signingkey = %q },\n", id.name, id.email, id.signingkey or ""))
  end
  file:write("}\n")
  file:close()
end

-- Set local Git config and update a global variable for status line.
local function set_git_config(name, email, gitSigningKey)
  vim.system({ "git", "config", "--local", "user.name", name }, { text = true }):wait()
  vim.system({ "git", "config", "--local", "user.email", email }, { text = true }):wait()
  -- Check if signing key is provided
  if gitSigningKey and gitSigningKey ~= "" then
    -- Verify if the GPG key exists in the system
    local key_check = vim.system({ "gpg", "--list-keys", gitSigningKey }, { text = true }):wait()

    if key_check.code == 0 then
      -- Key exists, configure Git to use it
      vim.system({ "git", "config", "--local", "user.signingkey", gitSigningKey }, { text = true }):wait()
      vim.system({ "git", "config", "--local", "commit.gpgsign", "true" }, { text = true }):wait()
      vim.notify("GPG signing key configured: " .. gitSigningKey, vim.log.levels.INFO)
    else
      -- Key doesn't exist, notify the user
      vim.system({ "git", "config", "--local", "commit.gpgsign", "false" }, { text = true }):wait()
      vim.notify(
        "GPG signing key '" .. gitSigningKey .. "' not found in your system. Please import the key first.",
        vim.log.levels.WARN
      )
    end
  else
    vim.system({ "git", "config", "--local", "commit.gpgsign", "false" }, { text = true }):wait()
  end

  vim.g.git_identity = " " .. email .. " "
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
  local global_signing_key = get_git_config("global", "user.signingkey")

  if local_name ~= "" and local_email ~= "" then
    -- Set our global variable too, so status line knows.
    vim.g.git_identity = " " .. local_email .. " "
    return
  end

  -- Load predefined identities.
  local identities = load_identities()
  local choices = {}
  local global_identity_prompt = "Use global Git user " .. global_name .. " <" .. global_email .. ">"
  local no_global_identity_prompt = "No global identity found."
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

  local function create_new_identity(identity)
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

        vim.ui.input({ prompt = "Enter GPG signing key (optional press enter to leave blank): " }, function(signing_key)
          if not signing_key or signing_key == "" then
            signing_key = nil
          end

          identity = { name = name, email = email, signingkey = signing_key }
          table.insert(identities, identity)
          save_identities(identities)
          set_git_config(identity.name, identity.email, identity.signingkey)
          vim.notify("Local Git user set to: " .. identity.name .. " <" .. identity.email .. ">", vim.log.levels.INFO)
        end)
      end)
    end)
    return identity
  end

  -- Add global identity option if available
  if global_email and global_name then
    table.insert(choices, global_identity_prompt)
  else
    table.insert(choices, no_global_identity_prompt)
  end

  table.insert(choices, new_identity_prompt)

  -- Build a list of choices formatted as "Name <email>".
  for _, id in ipairs(identities) do
    table.insert(choices, id.name .. " <" .. id.email .. ">")
  end

  -- Ensure snacks.nvim is loaded
  local function get_ui_select()
    if package.loaded["snacks"] and package.loaded["snacks.picker"] then
      return require("snacks.picker").select
    else
      return vim.ui.select
    end
  end

  -- Use the appropriate UI select function
  get_ui_select()(choices, {
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
      selected_identity = { name = global_name, email = global_email, global_signing_key }
      table.insert(identities, selected_identity)
      save_identities(identities)
      set_git_config(selected_identity.name, selected_identity.email, selected_identity.signingkey)
      vim.notify(
        "Local Git user set to: " .. selected_identity.name .. " <" .. selected_identity.email .. ">",
        vim.log.levels.INFO
      )
    elseif choice == new_identity_prompt then
      selected_identity = create_new_identity(selected_identity)
    elseif choice == no_global_identity_prompt then
      -- No action needed, just notify the user.
      vim.notify("No global identity found. Please set one or create a new identity.", vim.log.levels.INFO)
      selected_identity = create_new_identity(selected_identity)
    else
      -- Look up the selected identity.
      for _, id in ipairs(identities) do
        if choice == id.name .. " <" .. id.email .. ">" then
          selected_identity = id
          break
        end
      end
      if selected_identity then
        set_git_config(selected_identity.name, selected_identity.email, selected_identity.signingkey)
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

-- Wait for VimEnter event to delay identity checking until startup is complete
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Delay git identity check to ensure dashboard loads properly
    vim.defer_fn(function()
      ensure_git_config()
    end, 100)
  end,
  desc = "Set local git identity after startup is complete",
  once = true,
})

-- Handle directory changes after startup is complete
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    ensure_git_config()
  end,
  desc = "Set local git identity when changing directories",
})

-- Add a command to manually trigger the identity selection
vim.api.nvim_create_user_command("GitIdentity", function()
  -- Ensure snacks is loaded before running the command
  require("lazy").load({ plugins = { "snacks.nvim" } })
  ensure_git_config()
end, {
  desc = "Set local git identity for current repository",
})
