return {
  {
    "voldikss/vim-browser-search",
    keys = {
      {
        "<leader>gg",
        function()
          local query = vim.fn.input("Google: ")
          if query == "" then
            return
          end

          vim.cmd.BrowserSearch(query)
        end,
        mode = "n",
        desc = "Google search input",
      },
      {
        "<leader>gg",
        "<Plug>SearchVisual",
        mode = "x",
        remap = true,
        desc = "Google search selection",
      },
    },
    init = function()
      vim.g.browser_search_default_engine = "google"
    end,
  },
}
