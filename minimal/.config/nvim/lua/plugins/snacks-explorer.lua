---@class snacks.picker
local config = {
  picker = {
    sources = {
      explorer = {
        hidden = true,
        show_unlisted = true,
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
