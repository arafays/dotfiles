return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
        },
      },
    },
    terminal = {
      win = {
        position = "float",
        border = "single",
      },
    },
  },
}
