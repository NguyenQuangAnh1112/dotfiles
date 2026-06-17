return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      {
        "-",
        "<cmd>Oil<CR>",
        desc = "Open Oil",
      },
    },
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      float = {
        border = "rounded",
      },
    },
  },
}
