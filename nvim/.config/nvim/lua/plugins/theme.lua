return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      style = "night", -- Options: "storm", "moon", "day", "night"
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Dark mode
      colorscheme = "tokyonight",
    },
  },
}
