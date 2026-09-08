return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
      end,
      open_fold_hl_timeout = 150,
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local line = vim.fn.getline(lnum)
        local count = endLnum - lnum
        local suffix = line:match("{%s*$") and ("  ⋯ %d lines }"):format(count) or (" { ⋯ %d lines }"):format(count)
        local targetWidth = width - vim.fn.strdisplaywidth(suffix)
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "Comment" })
        return newVirtText
      end,
    },
    config = function(_, opts)
      vim.o.foldcolumn = "0"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      require("ufo").setup(opts)

      local keymap = vim.keymap.set
      keymap("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
      keymap("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
      keymap("n", "<leader>mm", function()
        require("ufo").closeFoldsWith(vim.v.count > 0 and vim.v.count or 1)
      end, { desc = "Close folds >= level 2" })
      keymap("n", "<leader>ma", function()
        local lnum = vim.fn.line(".")
        if vim.fn.foldclosed(lnum) ~= -1 then
          vim.cmd("normal! zO")
          return
        end

        local target_level = vim.v.count > 0 and (vim.v.count + 1) or 2
        if vim.fn.foldlevel(lnum) < target_level then
          return
        end

        while vim.fn.foldlevel(vim.fn.line(".")) > target_level do
          local prev = vim.fn.line(".")
          vim.cmd("normal! [z")
          if vim.fn.line(".") == prev then
            break
          end
        end

        vim.cmd("normal! zc")
      end, { desc = "Toggle method fold (safe with class fold)" })
    end,
  },
}
