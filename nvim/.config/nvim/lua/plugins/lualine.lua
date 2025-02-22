local function git_identity()
  return vim.g.git_identity or ""
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_b = {
          {
            git_identity,
            icon = "",
          },
          {
            "branch",
          },
        },
      },
    },
  },
}
