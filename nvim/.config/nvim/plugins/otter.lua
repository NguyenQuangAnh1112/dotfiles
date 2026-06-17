return {
  {
    "jmbuhr/otter.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
    },
    opts = {
      lsp = {
        diagnostic_update_events = { "BufWritePost", "InsertLeave", "TextChanged" },
        root_dir = function(_, bufnr)
          return vim.fs.root(bufnr or 0, {
            ".git",
            "package.json",
            "tsconfig.json",
            "jsconfig.json",
          }) or vim.fn.getcwd(0)
        end,
      },
      buffers = {
        set_filetype = true,
      },
      verbose = {
        no_code_found = false,
      },
    },
    config = function(_, opts)
      local otter = require("otter")
      local group = vim.api.nvim_create_augroup("user-otter-markdown", { clear = true })

      otter.setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function(args)
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(args.buf) or vim.bo[args.buf].filetype ~= "markdown" then
              return
            end

            vim.api.nvim_buf_call(args.buf, function()
              otter.activate(nil, true, true)
            end)
          end)
        end,
      })

      if vim.bo.filetype == "markdown" then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(0) and vim.bo.filetype == "markdown" then
            otter.activate(nil, true, true)
          end
        end)
      end
    end,
  },
}
