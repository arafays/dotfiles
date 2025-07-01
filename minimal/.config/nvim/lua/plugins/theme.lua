return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Dark mode
      colorscheme = "tokyonight-night",
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night", -- Options: "storm", "moon", "day", "night"
      transparent = true,
      terminal_colors = true,
      styles = {
        sidebars = "transparent", -- Style for sidebars, e.g. `qf`, `vista`, `terminal`, etc. Default is `transparent`
        floats = "transparent", -- Style for floating windows. Default is `transparent`
      },
    },
  }
}
