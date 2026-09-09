return {
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    cmd = {
      "MarkdownPreview",
      "MarkdownPreviewStop",
      "MarkdownPreviewToggle",
    },
    ft = { "markdown" },
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Toggle markdown preview" },
    },
    init = function()
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_combine_preview = 0
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/lua/user/markdown-preview.css"
      vim.g.mkdp_highlight_css = vim.fn.stdpath("config") .. "/lua/user/markdown-preview-highlight.css"
      vim.g.mkdp_theme = "dark"
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("user-markdown-preview", { clear = true })

      local function keep_browser_tabs_open()
        for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimLeave" })) do
          local group_name = autocmd.group_name or ""
          if group_name:match("^MKDP_REFRESH_INIT") then
            if autocmd.id then
              pcall(vim.api.nvim_del_autocmd, autocmd.id)
            else
              pcall(vim.api.nvim_clear_autocmds, { group = group_name, event = "VimLeave" })
            end
          end
        end
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = keep_browser_tabs_open,
      })
    end,
  },
}
