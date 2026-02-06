-- Define proper plugin specs
return {
  -- Configure lualine to show git identity
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.options = opts.options or {}
      -- opts.options.section_separators = { left = "", right = "" }
      -- opts.options.component_separators = { left = "", right = "" }

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
