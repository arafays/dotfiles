local function git_identity()
  return vim.g.git_identity or ""
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_b = {
          {
            git_identity,
            icon = "",
          },
          {
            "branch",
          },
        },
      },
    },
  },
}
