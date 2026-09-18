return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      format_on_save = {
        timeout_ms = 800,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        cs = {},
        gdscript = { "gdscript-formatter" },
        lua = { "stylua" },
        python = { "ruff_format" },
      },
    },
  },
}
