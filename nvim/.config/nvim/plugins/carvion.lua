return {
  {
    "zitrocode/carvion.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
    },
    config = function(_, opts)
      require("carvion").setup(opts)
      vim.cmd.colorscheme("carvion")

      -- Render mượt mà background trong suốt siêu tốc (thay thế hoàn toàn transparent.nvim)
      local extra_groups = {
        "NormalFloat", "FloatBorder", "SignColumn",
        "EndOfBuffer", "StatusLine", "StatusLineNC"
      }
      for _, group in ipairs(extra_groups) do
        vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
      end
    end,
  },
}
