local function open_in_new_tab(callback)
  vim.cmd("tabnew")
  callback()
end

local function open_in_vsplit(callback)
  vim.cmd("rightbelow vsplit")
  callback()
end

local function get_buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end

  return vim.fn.fnamemodify(name, ":~:.")
end

local function switch_to_existing_buffer_window(bufnr)
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        vim.api.nvim_set_current_tabpage(tabpage)
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end

  return false
end

local function open_buffer(bufnr, target)
  if target == "current" and switch_to_existing_buffer_window(bufnr) then
    return
  end

  if target == "tab" then
    vim.cmd("tabnew")
  elseif target == "split" then
    vim.cmd("rightbelow vsplit")
  end

  vim.api.nvim_win_set_buf(0, bufnr)
end

local function switch_buffers(target)
  target = target or "current"

  local buffers = vim.tbl_filter(function(buffer)
    return buffer.listed == 1 and vim.api.nvim_buf_is_valid(buffer.bufnr)
  end, vim.fn.getbufinfo({ buflisted = 1 }))

  table.sort(buffers, function(left, right)
    return left.lastused > right.lastused
  end)

  vim.ui.select(buffers, {
    prompt = "Buffers",
    format_item = function(buffer)
      local modified = buffer.changed == 1 and " [+]" or ""
      return ("%d  %s%s"):format(buffer.bufnr, get_buffer_name(buffer.bufnr), modified)
    end,
  }, function(buffer)
    if buffer then
      open_buffer(buffer.bufnr, target)
    end
  end)
end

local function open_help(topic, target)
  if target == "tab" then
    vim.cmd("tabnew")
  elseif target == "split" then
    vim.cmd("rightbelow split")
  end

  vim.cmd("help " .. vim.fn.fnameescape(topic))
end

local function help_tags(target)
  target = target or "current"
  local tags = vim.fn.getcompletion("", "help")

  vim.ui.select(tags, {
    prompt = "Help tags",
  }, function(topic)
    if topic and topic ~= "" then
      open_help(topic, target)
    end
  end)
end

local function tabs()
  local tabpages = vim.api.nvim_list_tabpages()

  vim.ui.select(tabpages, {
    prompt = "Tabs",
    format_item = function(tabpage)
      local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
      local wins = vim.api.nvim_tabpage_list_wins(tabpage)
      local bufnr = wins[1] and vim.api.nvim_win_get_buf(wins[1])
      local name = bufnr and get_buffer_name(bufnr) or "[No Name]"
      return ("%d  %s"):format(tabnr, name)
    end,
  }, function(tabpage)
    if tabpage then
      vim.api.nvim_set_current_tabpage(tabpage)
    end
  end)
end

local function sanitize_text(value)
  if type(value) ~= "string" then
    return value
  end

  return value:gsub("%z", ""):gsub("[\r\n]", " ")
end

local function patch_fff_sanitizer()
  local ok, list_renderer = pcall(require, "fff.picker_ui.list_renderer")
  if not ok or list_renderer._user_sanitized then
    return
  end

  local orig_render = list_renderer.render
  list_renderer.render = function(ctx, list_buf, list_win, ns_id)
    if ctx and ctx.items then
      for _, item in ipairs(ctx.items) do
        if item.name then
          item.name = sanitize_text(item.name)
        end
        if item.relative_path then
          item.relative_path = sanitize_text(item.relative_path)
        end
        if item.line_content then
          item.line_content = sanitize_text(item.line_content)
        end
      end
    end
    return orig_render(ctx, list_buf, list_win, ns_id)
  end

  list_renderer._user_sanitized = true
end

local function live_grep()
  require("fff").live_grep()
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = true,
    keys = {
      {
        "<leader>.",
        function()
          require("fff").find_files()
        end,
        desc = "Find files",
      },
      {
        "<leader>t.",
        function()
          open_in_new_tab(function()
            require("fff").find_files()
          end)
        end,
        desc = "New tab and find files",
      },
      {
        "<leader>/",
        live_grep,
        desc = "Search project",
      },
      {
        "<leader>*",
        function()
          require("fff").live_grep({ query = vim.fn.expand("<cword>") })
        end,
        desc = "Search word under cursor",
      },
      {
        "<leader>t/",
        function()
          open_in_new_tab(live_grep)
        end,
        desc = "New tab and search project",
      },
      {
        "<leader>,",
        function()
          switch_buffers("current")
        end,
        desc = "Switch buffer",
      },
      {
        "<leader>t,",
        function()
          switch_buffers("tab")
        end,
        desc = "New tab and switch buffer",
      },
      {
        "<leader>?",
        function()
          help_tags("current")
        end,
        desc = "Help tags",
      },
      {
        "<leader>t?",
        function()
          help_tags("tab")
        end,
        desc = "New tab and help tags",
      },
      {
        "<leader>ft",
        tabs,
        desc = "Search tabs",
      },
      {
        "<leader>s.",
        function()
          open_in_vsplit(function()
            require("fff").find_files()
          end)
        end,
        desc = "Vsplit and find files",
      },
      {
        "<leader>s,",
        function()
          switch_buffers("split")
        end,
        desc = "Vsplit and switch buffer",
      },
      {
        "<leader>s/",
        function()
          open_in_vsplit(live_grep)
        end,
        desc = "Vsplit and live grep",
      },
      {
        "<leader>s?",
        function()
          help_tags("split")
        end,
        desc = "Vsplit and help tags",
      },
    },
    opts = {
      lazy_sync = true,
      max_results = 100,
      wrap_around = true,
      layout = {
        height = 0.85,
        width = 0.85,
        prompt_position = "top",
        preview_position = "right",
        preview_size = 0.55,
        flex = { size = 130, wrap = "top" },
        min_list_height = 12,
        path_shorten_strategy = "middle_number",
      },
      preview = {
        enabled = true,
        line_numbers = true,
        wrap_lines = false,
        filetypes = {
          markdown = { wrap_lines = true },
          text = { wrap_lines = true },
          svg = { wrap_lines = true },
        },
      },
      git = {
        status_text_color = true,
      },
      grep = {
        smart_case = true,
        modes = { "plain", "regex", "fuzzy" },
        trim_whitespace = true,
        max_matches_per_file = 80,
        time_budget_ms = 200,
      },
    },
    config = function(_, opts)
      require("fff").setup(opts)
      patch_fff_sanitizer()
    end,
  },
}
