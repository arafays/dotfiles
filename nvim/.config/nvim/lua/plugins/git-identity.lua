-- Define proper plugin specs
return {
  -- Configure snacks.nvim for better UI elements
  {
    "folke/snacks.nvim",
    event = "VimEnter",
    lazy = false,
    priority = 100,
    config = function()
      require("snacks").setup({
        picker = {
          sources = {
            select = {
              hidden = false,
            },
            explorer = {
              hidden = true,
            },
            find = {
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
      })

      -- Set up the UI functions after LazyVim has fully started
      vim.defer_fn(function()
        -- Override vim.ui.select and vim.ui.input to use snacks
        vim.ui.select = require("snacks.picker").select
        vim.ui.input = require("snacks.picker").input
      end, 200)
    end,
  },

  -- Configure lualine to show git identity
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.options = opts.options or {}
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "", right = "" }

      opts.sections = opts.sections or {}
      opts.sections.lualine_b = opts.sections.lualine_b or {}

      table.insert(opts.sections.lualine_b, {
        function()
          return vim.g.git_identity
        end,
        cond = function()
          return vim.g.git_identity ~= nil
        end,
        icon = "",
      })
      table.insert(opts.sections.lualine_b, "branch")
    end,
  },
}
