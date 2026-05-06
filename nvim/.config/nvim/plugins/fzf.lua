local function switch_to_buffer_or_tab(selected, opts)
  local entry = require("fzf-lua.path").entry_to_file(selected[1], opts)
  local bufnr = entry.bufnr

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        vim.api.nvim_set_current_tabpage(tabpage)
        vim.api.nvim_set_current_win(win)
        return
      end
    end
  end

  vim.api.nvim_win_set_buf(0, bufnr)
end

local function find_files()
  local fzf = require("fzf-lua")
  local git_root = vim.fs.root(0, ".git")

  if git_root then
    fzf.git_files({ cwd = git_root })
    return
  end

  fzf.files()
end

local function find_files_in_new_tab()
  local git_root = vim.fs.root(0, ".git")
  local fzf = require("fzf-lua")

  vim.cmd("tabnew")

  if git_root then
    fzf.git_files({ cwd = git_root })
    return
  end

  fzf.files()
end

local function open_in_new_tab(callback)
  vim.cmd("tabnew")
  callback()
end

local function switch_buffers()
  require("fzf-lua").buffers({
    actions = {
      ["enter"] = switch_to_buffer_or_tab,
    },
  })
end

return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    cmd = { "FzfLua" },
    keys = {
      {
        "<leader>.",
        find_files,
        desc = "Find files",
      },
      {
        "<leader>t.",
        find_files_in_new_tab,
        desc = "New tab and find files",
      },
      {
        "<leader>,",
        switch_buffers,
        desc = "Switch buffer",
      },
      {
        "<leader>t,",
        function()
          open_in_new_tab(function()
            require("fzf-lua").buffers()
          end)
        end,
        desc = "New tab and switch buffer",
      },
      { "<leader>/", "<cmd>FzfLua live_grep<CR>", desc = "Search project" },
      {
        "<leader>t/",
        function()
          open_in_new_tab(function()
            require("fzf-lua").live_grep()
          end)
        end,
        desc = "New tab and search project",
      },
      { "<leader>?", "<cmd>FzfLua help_tags<CR>", desc = "Help tags" },
      {
        "<leader>t?",
        function()
          open_in_new_tab(function()
            require("fzf-lua").help_tags()
          end)
        end,
        desc = "New tab and help tags",
      },
      { "<leader>ft", "<cmd>FzfLua tabs<CR>", desc = "Search tabs" },
    },
    opts = {
      "max-perf",
      winopts = {
        height = 0.85,
        width = 0.8,
        backdrop = false,
        preview = {
          default = "bat",
          hidden = true,
        },
      },
      defaults = {
        file_icons = false,
        color_icons = false,
        git_icons = false,
      },
      previewers = {
        bat = {
          args = "--color=always --style=numbers --line-range=:200",
        },
        bat_native = {
          args = "--color=always --style=numbers --line-range=:200",
        },
      },
      files = {
        hidden = true,
        fd_opts = "--color=never --type f --type l --strip-cwd-prefix --hidden --follow --exclude .git --exclude .cache --exclude node_modules --exclude .npm --exclude .venv --exclude __pycache__",
        rg_opts = "--color=never --files --hidden --follow -g '!.git/*' -g '!.cache/*' -g '!node_modules/*' -g '!.npm/*' -g '!.venv/*' -g '!__pycache__/*'",
      },
      git = {
        files = {
          cmd = "git ls-files --cached --others --exclude-standard",
        },
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden --follow --glob '!.git/*' --glob '!.cache/*' --glob '!node_modules/*' --glob '!.npm/*' --glob '!.venv/*' --glob '!__pycache__/*' -e",
        fzf_opts = {
          ["--ansi"] = true,
        },
      },
      fzf_colors = {
        gutter = "-1",
      },
    },
    config = function(_, opts)
      require("fzf-lua").setup(opts)

      local groups = {
        "FzfLuaBorder",
        "FzfLuaTitle",
        "FzfLuaBackdrop",
        "FzfLuaPreviewBorder",
        "FzfLuaPreviewTitle",
        "FzfLuaFzfBorder",
        "FzfLuaFzfGutter",
      }

      local function clear_bg()
        for _, group in ipairs(groups) do
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
          if ok then
            hl.bg = "none"
            hl.ctermbg = "none"
            vim.api.nvim_set_hl(0, group, hl)
          end
        end
      end

      clear_bg()

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = clear_bg,
      })
    end,
  },
}
