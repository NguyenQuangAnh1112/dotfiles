return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle render markdown" },
    },
    opts = {
      anti_conceal = { enabled = false },
      win_options = {
        concealcursor = {
          rendered = "n", -- Giữ render khi di chuyển con trỏ ở normal mode
        },
      },
      html = { enabled = false },
      latex = { enabled = false },
      yaml = { enabled = false },
    },
  },
}
