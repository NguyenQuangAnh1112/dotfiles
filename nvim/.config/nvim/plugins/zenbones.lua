return {
  {
    "mcchrish/zenbones.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.zenbones_transparent_background = true
      vim.cmd.colorscheme("zenbones")

      local transparent_groups = {
        "Normal", "NormalNC", "NormalFloat", "FloatBorder",
        "SignColumn", "EndOfBuffer", "StatusLine", "StatusLineNC",
        "TabLine", "TabLineFill", "TabLineSel", "WinSeparator",
        "LineNr", "CursorLineNr", "FoldColumn", "Pmenu", "PmenuSel",
      }

      for _, group in ipairs(transparent_groups) do
        vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
      end

      vim.api.nvim_set_hl(0, "LineNr", { fg = "#5c5c5c", bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#7a7a7a", bg = "NONE", ctermbg = "NONE", bold = true })
    end,
  },
}
