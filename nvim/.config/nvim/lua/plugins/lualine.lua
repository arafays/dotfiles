local function git_identity()
  return vim.g.git_identity or ""
end

---@module "lualine"
local config = {
  options = {
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  sections = {
    lualine_b = {
      {
        git_identity,
        icon = "",
      },
      {
        "branch",
      },
    },
  },
}

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = config,
  },
}
