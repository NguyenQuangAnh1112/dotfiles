return {
  {
    "echasnovski/mini.nvim",
    version = false,
    event = { "BufReadPost", "BufNewFile", "InsertEnter", "VeryLazy" },
    config = function()
      local indentscope = require("mini.indentscope")

      require("mini.ai").setup()
      indentscope.setup({
        draw = {
          delay = 0,
          animation = indentscope.gen_animation.none(),
        },
        symbol = "│",
        options = {
          try_as_border = true,
        },
      })
      require("mini.pairs").setup()
      require("mini.surround").setup({
        mappings = {
          add = "ys",
          delete = "ds",
          find = "",
          find_left = "",
          highlight = "",
          replace = "cs",
          update_n_lines = "",
          suffix_last = "",
          suffix_next = "",
        },
        search_method = "cover_or_next",
      })
      vim.keymap.del("x", "ys")
      vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add("visual")<CR>]], { silent = true, desc = "Add surrounding" })
      vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Add surrounding to line" })

      local pick = require("mini.pick")
      pick.setup({
        window = {
          config = {
            border = "rounded",
          },
        },
      })
      vim.ui.select = pick.ui_select

      local diff = require("mini.diff")
      diff.setup({
        view = {
          style = "sign",
          signs = {
            add = "",
            change = "",
            delete = "",
          },
        },
        options = {
          wrap_goto = true,
        },
      })

      vim.api.nvim_set_hl(0, "MiniDiffSignAdd", {})
      vim.api.nvim_set_hl(0, "MiniDiffSignChange", {})
      vim.api.nvim_set_hl(0, "MiniDiffSignDelete", {})

      local keymap = vim.keymap.set

      -- Navigation hunks (quay vòng)
      keymap({ "n", "x" }, "]c", function() diff.goto_hunk("next", { wrap = true }) end, { desc = "Next diff hunk (wrap)" })
      keymap({ "n", "x" }, "[c", function() diff.goto_hunk("prev", { wrap = true }) end, { desc = "Previous diff hunk (wrap)" })

      -- Toggle diff overlay
      keymap("n", "<leader>hd", function() diff.toggle_overlay(0) end, { desc = "Toggle diff overlay" })
      keymap("n", "<leader>do", function() diff.toggle_overlay(0) end, { desc = "Toggle diff overlay" })

      -- Stage / Reset hunk
      keymap("n", "<leader>hs", function() return diff.operator("apply") .. "gh" end, { expr = true, remap = true, desc = "Stage hunk" })
      keymap("x", "<leader>hs", function() return diff.operator("apply") end, { expr = true, desc = "Stage selection" })
      keymap("n", "<leader>hr", function() return diff.operator("reset") .. "gh" end, { expr = true, remap = true, desc = "Reset hunk" })
      keymap("x", "<leader>hr", function() return diff.operator("reset") end, { expr = true, desc = "Reset selection" })
    end,
  },
}
