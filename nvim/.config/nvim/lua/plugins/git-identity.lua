-- Define proper plugin specs
return {
  -- Dressing.nvim for better UI elements
  {
    "stevearc/dressing.nvim",
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  },

  -- Configure lualine to show git identity
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      if opts and opts.sections and opts.sections.lualine_b then
        table.insert(opts.sections.lualine_b, {
          function()
            return vim.g.git_identity
          end,
          cond = function()
            return vim.g.git_identity ~= nil
          end,
          icon = { "" },
        })
        table.insert(opts.sections.lualine_b, "branch")
      end
    end,
  },
}
