return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    cmd = { "Yazi" },
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>y",
        "<cmd>Yazi<CR>",
        mode = { "n", "v" },
        desc = "Open Yazi",
      },
      {
        "<leader>ty",
        function()
          vim.cmd("tabnew")
          vim.cmd("Yazi")
        end,
        mode = "n",
        desc = "New tab and open Yazi",
      },
    },
    opts = {
      open_for_directories = false,
      yazi_floating_window_border = "rounded",
    },
  },
}
