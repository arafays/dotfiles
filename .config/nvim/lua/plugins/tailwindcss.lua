return {
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    opts = {
      servers = {
        tailwindcss = {
          root_dir = function(fname)
            -- Ensure fname is always a real file path, not a number
            fname = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(0)
            if fname == "" then
              return nil
            end

            -- Find nearest package.json
            local package_json = vim.fs.find({ "package.json" }, { path = fname, upward = true })[1]
            if not package_json then
              return nil
            end

            -- Read package.json reliably
            local ok, json = pcall(vim.fn.readfile, package_json)
            if not ok or not json then
              return nil
            end

            local content = table.concat(json, "\n")

            -- Check if the project uses Tailwind (works for v3 + v4)
            if content:match('"tailwindcss"%s*:') then
              return vim.fs.dirname(package_json)
            end

            return nil
          end,
        },
      },
    },
  },
}
