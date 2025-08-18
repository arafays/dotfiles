return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
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
  -- {
  --   "crusoexia/vim-monokai",
  --   priority = 1000, -- ensure it loads before LazyVim
  --   lazy = false,
  -- },
}

-- To live preview and switch themes, use :Telescope colorscheme
-- You can also map it to a key in your user config, e.g.:
-- vim.keymap.set("n", "<leader>ut", "<cmd>Telescope colorscheme<cr>", { desc = "Change Colorscheme" })
