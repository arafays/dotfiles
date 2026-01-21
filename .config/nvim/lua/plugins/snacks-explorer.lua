---@module "snacks"
---@class snacks.picker
local config = {
  ---@class snacks.picker.sources.Config
  picker = {
    sources = {
      explorer = {
        hidden = true,
        show_unlinked = true,
        watch = false, -- Disable file watching to prevent errors
      },
    },
  },
  terminal = {
    win = {
      position = "float",
      border = "single",
    },
  },
  scroll = {
    enabled = false, -- Disable scrolling animations
  },
}

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = config,
}