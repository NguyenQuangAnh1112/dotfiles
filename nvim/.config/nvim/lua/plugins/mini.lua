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

      -- Hỗ trợ hiển thị diff cho file mới tinh (untracked)
      local function setup_untracked_diff(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local path = vim.api.nvim_buf_get_name(buf)
        if path == "" or vim.fn.filereadable(path) == 0 then
          return
        end

        local dir = vim.fs.dirname(path)
        vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --is-inside-work-tree 2>/dev/null")
        if vim.v.shell_error ~= 0 then
          return
        end

        vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " ls-files --error-unmatch " .. vim.fn.shellescape(path) .. " 2>/dev/null")
        if vim.v.shell_error ~= 0 then
          -- File chưa được track trong Git: đặt source là none để Git watcher không reset ref_text về nil
          vim.b[buf].minidiff_config = { source = diff.gen_source.none() }
          diff.disable(buf)
          diff.enable(buf)
          diff.set_ref_text(buf, "")
        else
          if vim.b[buf].minidiff_config ~= nil then
            vim.b[buf].minidiff_config = nil
            diff.disable(buf)
            diff.enable(buf)
          end
        end
      end

      local untracked_group = vim.api.nvim_create_augroup("user-mini-diff-untracked", { clear = true })
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = untracked_group,
        callback = function(args)
          if vim.b[args.buf].minidiff_checked then return end
          vim.b[args.buf].minidiff_checked = true
          setup_untracked_diff(args.buf)
        end,
      })
      setup_untracked_diff(vim.api.nvim_get_current_buf())

      local function is_untracked(buf)
        local path = vim.api.nvim_buf_get_name(buf)
        if path == "" or vim.fn.filereadable(path) == 0 then
          return false, path
        end
        local dir = vim.fs.dirname(path)
        vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --is-inside-work-tree 2>/dev/null")
        if vim.v.shell_error ~= 0 then
          return false, path
        end
        vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " ls-files --error-unmatch " .. vim.fn.shellescape(path) .. " 2>/dev/null")
        return vim.v.shell_error ~= 0, path, dir
      end

      local function stage_hunk_normal()
        local buf = vim.api.nvim_get_current_buf()
        local untracked, path, dir = is_untracked(buf)
        if untracked then
          local rel = vim.fn.fnamemodify(path, ":~:.")
          vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " add " .. vim.fn.shellescape(path))
          if vim.v.shell_error == 0 then
            vim.notify("Đã stage file mới: " .. rel, vim.log.levels.INFO)
            vim.b[buf].minidiff_config = nil
            diff.disable(buf)
            diff.enable(buf)
          else
            vim.notify("Lỗi khi git add: " .. rel, vim.log.levels.ERROR)
          end
          return ""
        end
        return diff.operator("apply") .. "gh"
      end

      local function stage_hunk_visual()
        local buf = vim.api.nvim_get_current_buf()
        local untracked, path, dir = is_untracked(buf)
        if untracked then
          local rel = vim.fn.fnamemodify(path, ":~:.")
          vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " add " .. vim.fn.shellescape(path))
          if vim.v.shell_error == 0 then
            vim.notify("Đã stage file mới: " .. rel, vim.log.levels.INFO)
            vim.b[buf].minidiff_config = nil
            diff.disable(buf)
            diff.enable(buf)
          else
            vim.notify("Lỗi khi git add: " .. rel, vim.log.levels.ERROR)
          end
          return ""
        end
        return diff.operator("apply")
      end

      local function reset_hunk_normal()
        local buf = vim.api.nvim_get_current_buf()
        local untracked, path = is_untracked(buf)
        if untracked then
          local rel = vim.fn.fnamemodify(path, ":~:.")
          local choice = vim.fn.confirm("File mới chưa có trong Git (" .. rel .. "). Bạn có muốn xoá file này không?", "&Xoá file\n&Không", 2)
          if choice == 1 then
            vim.fn.delete(path)
            vim.cmd("bdelete! " .. buf)
            vim.notify("Đã xoá file: " .. rel, vim.log.levels.INFO)
          end
          return ""
        end
        return diff.operator("reset") .. "gh"
      end

      local function reset_hunk_visual()
        local buf = vim.api.nvim_get_current_buf()
        local untracked = is_untracked(buf)
        if untracked then
          return ""
        end
        return diff.operator("reset")
      end

      local keymap = vim.keymap.set

      -- Navigation hunks (tự động quay vòng đầu <-> cuối)
      keymap({ "n", "x" }, "]c", function() diff.goto_hunk("next", { wrap = true }) end, { desc = "Next diff hunk (wrap)" })
      keymap({ "n", "x" }, "[c", function() diff.goto_hunk("prev", { wrap = true }) end, { desc = "Previous diff hunk (wrap)" })

      -- Toggle diff overlay (xem chi tiết diff & dòng bị xoá ngay tại buffer)
      keymap("n", "<leader>hd", function() diff.toggle_overlay(0) end, { desc = "Toggle diff overlay" })
      keymap("n", "<leader>do", function() diff.toggle_overlay(0) end, { desc = "Toggle diff overlay" })

      -- Stage (apply) hunk hoặc file mới
      keymap("n", "<leader>hs", stage_hunk_normal, { expr = true, remap = true, desc = "Stage hunk or untracked file" })
      keymap("x", "<leader>hs", stage_hunk_visual, { expr = true, desc = "Stage selection or untracked file" })

      -- Reset hunk hoặc xoá file mới
      keymap("n", "<leader>hr", reset_hunk_normal, { expr = true, remap = true, desc = "Reset hunk or delete untracked file" })
      keymap("x", "<leader>hr", reset_hunk_visual, { expr = true, desc = "Reset selection" })

      -- Điều hướng thông minh cho n và N:
      -- - Khi đang tìm kiếm: n/N là nhảy kết quả tìm kiếm (Next/Prev match)
      -- - Khi đang bật Diff Overlay (<leader>hd) và không tìm kiếm: n/N là nhảy giữa các diff hunk (tự quay vòng)
      -- - Bình thường: n/N là phím tìm kiếm mặc định của Vim
      local function is_search_active()
        return vim.v.hlsearch == 1 and vim.fn.getreg("/") ~= ""
      end

      local function is_diff_overlay_open()
        local ok, data = pcall(diff.get_buf_data, 0)
        return ok and data ~= nil and data.overlay == true
      end

      local function nav_next()
        if not is_search_active() and is_diff_overlay_open() then
          diff.goto_hunk("next", { wrap = true })
        else
          pcall(vim.cmd, "normal! " .. vim.v.count1 .. "n")
        end
      end

      local function nav_prev()
        if not is_search_active() and is_diff_overlay_open() then
          diff.goto_hunk("prev", { wrap = true })
        else
          pcall(vim.cmd, "normal! " .. vim.v.count1 .. "N")
        end
      end

      keymap({ "n", "x" }, "n", nav_next, { desc = "Next search match or diff hunk (wrap in overlay)" })
      keymap({ "n", "x" }, "N", nav_prev, { desc = "Prev search match or diff hunk (wrap in overlay)" })
    end,
  },
}
