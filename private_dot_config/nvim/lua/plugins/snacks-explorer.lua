---@module "snacks"
---@class snacks.picker
local config = {
  ---@class snacks.picker.sources.Config
  picker = {
    sources = {
      explorer = {
        hidden = true,
        show_unlinked = true,
      },
    },
  },
  terminal = {
    win = {
      position = "float",
      border = "single",
    },
  },
}

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = config,
}
