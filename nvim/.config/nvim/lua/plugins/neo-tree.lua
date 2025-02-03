-- make neotree show hidden files
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = { width = 32 },
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
      },
    },
  },
}
