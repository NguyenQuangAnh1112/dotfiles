return {
  {
    "pixelsandpointers/slang.nvim",
    ft = { "slang", "shaderslang", "hlsl" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
      "williamboman/mason.nvim",
    },
    opts = function()
      local mason_slangd = vim.fn.stdpath("data") .. "/mason/bin/slangd"
      local slangd_path = nil

      if vim.fn.executable(mason_slangd) == 1 then
        slangd_path = mason_slangd
      elseif vim.fn.executable("slangd") == 1 then
        slangd_path = "slangd"
      end

      return {
        slangd_path = slangd_path,
        auto_format = true,
        inlay_hints = true,
      }
    end,
  },
}
