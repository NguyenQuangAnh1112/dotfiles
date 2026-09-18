return {
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
      { "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Neogit commit popup" },
    },
    opts = {
      disable_hint = false,
      treesitter_diff_highlight = true,
      graph_style = "unicode",
    },
  },
}
