return {
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    opts = {
      servers = {
        tailwindcss = {
          root_dir = function(fname)
            local package_json = vim.fs.dirname(vim.fs.find("package.json", { path = fname, upward = true })[1])
            if not package_json then
              return nil
            end
            local file = io.open(package_json .. "/package.json", "r")
            if not file then
              return nil
            end
            local content = file:read("*a")
            file:close()

            if content:match('"tailwindcss"%s*:') then
              return package_json
            else
              return nil
            end
          end,
        },
      },
    },
  },
}
