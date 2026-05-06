return {
  "nanozuki/tabby.nvim",
  event = "VimEnter",

  config = function()
    -- Cài đặt màu nền trong suốt (NONE) và màu chữ giống hệt tmux.conf
    vim.api.nvim_set_hl(0, "TmuxLikeFill", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "TmuxLikeTab", { fg = "#9a9a9a", bg = "NONE" })
    vim.api.nvim_set_hl(0, "TmuxLikeSel", { fg = "#ffffff", bg = "NONE", bold = true })

    local theme = {
      fill = "TmuxLikeFill",
      current_tab = "TmuxLikeSel",
      tab = "TmuxLikeTab",
    }

    require("tabby.tabline").set(function(line)
      return {
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and theme.current_tab or theme.tab
          return {
            -- Phải gắn khoảng trắng trực tiếp vào chuỗi vì tpipeline sẽ bỏ qua thuộc tính margin của tabby
            tab.number() .. ":" .. tab.name() .. "  ",
            hl = hl,
          }
        end),
        hl = theme.fill,
      }
    end)
  end,
}
