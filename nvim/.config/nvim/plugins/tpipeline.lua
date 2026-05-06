return {
  "vimpostor/vim-tpipeline",
  lazy = false,
  init = function()
    vim.g.tpipeline_tabline = 1
    -- Only embed the left side so tmux keeps its native status-right.
    vim.g.tpipeline_split = 0
    vim.g.tpipeline_embedopts = {
      "status-left-length 200",
      "status-left '#(cat #{socket_path}-\\#{session_id}-vimbridge)'",
      "status-right '#[fg=#9a9a9a]#S-%H:%M'",
    }
  end,
  config = function()
    local group = vim.api.nvim_create_augroup("user-tpipeline-tabline", { clear = true })

    local function ensure_tpipeline_ready()
      if vim.g.tpipeline_fillchar ~= nil then
        return true
      end

      local ok = pcall(vim.fn["tpipeline#initialize"])
      return ok and vim.g.tpipeline_fillchar ~= nil
    end

    local function refresh_tpipeline()
      if not ensure_tpipeline_ready() then
        return
      end

      pcall(vim.fn["tpipeline#update"])
    end

    -- Let tabby install its tabline first, then point tpipeline at it.
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      callback = function()
        vim.schedule(function()
          vim.g.tpipeline_statusline = vim.o.tabline ~= "" and vim.o.tabline or "%!TabbyRenderTabline()"
          refresh_tpipeline()
        end)
      end,
    })

    vim.api.nvim_create_autocmd({ "TabEnter", "TabNewEntered", "TabClosed" }, {
      group = group,
      callback = function()
        vim.schedule(function()
          refresh_tpipeline()
        end)
      end,
    })
  end,
}
