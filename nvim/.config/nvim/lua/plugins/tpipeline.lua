return {
  "vimpostor/vim-tpipeline",
  lazy = false,
  cond = function()
    return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
  end,
  init = function()
    vim.g.tpipeline_tabline = 1
    vim.g.tpipeline_statusline = "%!v:lua.user_tabline()"
    -- Tắt cập nhật khi di chuyển con trỏ (tabline không cần CursorMoved, tiết kiệm CPU)
    vim.g.tpipeline_cursormoved = 0
    -- Giữ màu nền trong suốt của tmux statusbar (không lấy bg từ StatusLine/Normal)
    vim.g.tpipeline_preservebg = 1
    vim.g.tpipeline_restore = 0
    vim.g.tpipeline_focuslost = 0
    vim.g.tpipeline_split = 0
    -- Thiết lập status-left đọc trực tiếp biến @vim_tabline của riêng từng window
    vim.g.tpipeline_embedopts = {
      "status-left-length 200",
      "status-left '#{@vim_tabline}'",
      "status-right ''",
    }
  end,
  config = function()
    local group = vim.api.nvim_create_augroup("user-tpipeline-tabline", { clear = true })
    local pane_id = vim.env.TMUX_PANE

    local function ensure_tpipeline_ready()
      if vim.g.tpipeline_fillchar == nil then
        pcall(vim.fn["tpipeline#initialize"])
      end
      return vim.g.tpipeline_fillchar ~= nil
    end

    -- Cập nhật biến @vim_tabline của riêng window chứa pane Neovim này
    local function update_window_tabline()
      if not pane_id or pane_id == "" or not ensure_tpipeline_ready() then
        return
      end

      local ok, tp = pcall(require, "tpipeline.main")
      if ok and tp then
        local line = tp.update()
        if line then
          vim.system({ "tmux", "set-option", "-w", "-t", pane_id, "@vim_tabline", line }, nil, function()
            vim.system({ "tmux", "refresh-client", "-S" })
          end)
        end
      end
    end

    -- Gỡ bỏ biến @vim_tabline của riêng window này khi Neovim đóng
    local function clear_window_tabline()
      if pane_id and pane_id ~= "" then
        vim.fn.system(string.format("tmux set-option -w -u -t '%s' @vim_tabline 2>/dev/null; tmux refresh-client -S 2>/dev/null", pane_id))
      end
    end

    -- Cập nhật khi khởi động, đổi tab, đổi buffer, lưu file, sửa đổi file hoặc focus
    vim.api.nvim_create_autocmd({
      "VimEnter",
      "FocusGained",
      "TabEnter",
      "TabNewEntered",
      "TabClosed",
      "BufEnter",
      "BufWritePost",
      "BufModifiedSet",
      "TermOpen",
    }, {
      group = group,
      callback = function()
        vim.schedule(update_window_tabline)
      end,
    })

    -- Dọn dẹp sạch sẽ biến @vim_tabline của window này khi thoát hẳn Neovim
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = clear_window_tabline,
    })
  end,
}
