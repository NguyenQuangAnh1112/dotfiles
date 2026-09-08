return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true,
      dimInactive = false,
      terminalColors = true,
      theme = "dragon",
      background = {
        dark = "dragon",
        light = "lotus",
      },
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      overrides = function(colors)
        local theme = colors.theme
        return {
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          FloatTitle = { bg = "none" },

          Pmenu = { fg = theme.ui.pmenu.fg, bg = "none" },
          PmenuKind = { bg = "none" },
          PmenuExtra = { bg = "none" },
          PmenuSel = { fg = theme.ui.pmenu.fg_sel, bg = theme.ui.pmenu.bg_sel },
          PmenuSbar = { bg = "none" },
          PmenuThumb = { bg = theme.ui.pmenu.bg_thumb },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd("colorscheme kanagawa-dragon")

      local transparent_groups = {
        "Normal", "NormalNC", "NormalFloat", "FloatBorder",
        "SignColumn", "EndOfBuffer", "TabLine", "TabLineFill",
        "TabLineSel", "WinSeparator", "LineNr", "CursorLineNr", "FoldColumn",
        "Pmenu", "PmenuKind", "PmenuExtra", "PmenuSbar",
      }

      for _, group in ipairs(transparent_groups) do
        local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
        hl.bg = "NONE"
        hl.ctermbg = "NONE"
        vim.api.nvim_set_hl(0, group, hl)
      end
    end,
  },
}
