return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      render_modes = true,
      html = { enabled = false },
      latex = { enabled = false },
      yaml = { enabled = false },
    },
    config = function(_, opts)
      local render_markdown = require("render-markdown")
      local group = vim.api.nvim_create_augroup("user-render-markdown", { clear = true })

      render_markdown.setup(opts)

      local function attach(buf)
        if vim.b[buf].render_markdown_insert_toggle_attached then
          return
        end

        vim.b[buf].render_markdown_insert_toggle_attached = true
        vim.api.nvim_buf_call(buf, function()
          render_markdown.buf_enable()
        end)

        vim.api.nvim_create_autocmd("InsertEnter", {
          group = group,
          buffer = buf,
          callback = function()
            render_markdown.buf_disable()
          end,
        })

        vim.api.nvim_create_autocmd("InsertLeave", {
          group = group,
          buffer = buf,
          callback = function()
            render_markdown.buf_enable()
          end,
        })
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function(args)
          attach(args.buf)
        end,
      })

      if vim.bo.filetype == "markdown" then
        attach(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
