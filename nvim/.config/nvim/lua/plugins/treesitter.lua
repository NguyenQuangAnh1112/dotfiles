return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      ts.setup()

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local file_path = vim.api.nvim_buf_get_name(args.buf)
          if file_path ~= "" then
            local ok, stats = pcall(vim.uv.fs_stat, file_path)
            if ok and stats and stats.size > 500 * 1024 then
              return
            end
          end

          pcall(vim.treesitter.start, args.buf)

          if vim.bo[args.buf].filetype == "python" then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        move = {
          set_jumps = true,
        },
      })

      local keymap = vim.keymap.set
      local move = require("nvim-treesitter-textobjects.move")

      keymap({ "n", "x", "o" }, "]m", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function start" })

      keymap({ "n", "x", "o" }, "]M", function()
        move.goto_next_end("@function.outer", "textobjects")
      end, { desc = "Next function end" })

      keymap({ "n", "x", "o" }, "[m", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous function start" })

      keymap({ "n", "x", "o" }, "[M", function()
        move.goto_previous_end("@function.outer", "textobjects")
      end, { desc = "Previous function end" })

      keymap({ "n", "x", "o" }, "]k", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class start" })

      keymap({ "n", "x", "o" }, "]K", function()
        move.goto_next_end("@class.outer", "textobjects")
      end, { desc = "Next class end" })

      keymap({ "n", "x", "o" }, "[k", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class start" })

      keymap({ "n", "x", "o" }, "[K", function()
        move.goto_previous_end("@class.outer", "textobjects")
      end, { desc = "Previous class end" })
    end,
  },
}
