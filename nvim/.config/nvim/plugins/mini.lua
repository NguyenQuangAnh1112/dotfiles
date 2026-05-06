return {
  {
    "echasnovski/mini.nvim",
    version = false,
    event = { "InsertEnter", "VeryLazy" },
    config = function()
      local indentscope = require("mini.indentscope")

      require("mini.ai").setup()
      require("mini.comment").setup()
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
          add = "gsa",
          delete = "gsd",
          replace = "gsr",
          find = "gsf",
          find_left = "gsF",
          highlight = "gsh",
          update_n_lines = "gsn",
          suffix_last = "l",
          suffix_next = "n",
        },
      })
    end,
  },
}
