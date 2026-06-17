local function open_in_new_tab(callback)
  vim.cmd("tabnew")
  callback()
end

local function open_in_vsplit(callback)
  vim.cmd("rightbelow vsplit")
  callback()
end

local function open_select_picker(opts)
  local source_items = opts.items or {}
  local format_item = opts.format_item or tostring
  local on_select = opts.on_select
  local prompt = opts.prompt or "Select"
  local query = ""
  local cursor = 1
  local top = 1
  local filtered = {}
  local ns = vim.api.nvim_create_namespace("user-fff-select-picker")

  local columns = vim.o.columns
  local lines = vim.o.lines
  local width = math.max(48, math.floor(columns * 0.58))
  width = math.min(width, columns - 6)
  local list_height = math.min(opts.height or 14, math.max(6, lines - 8))
  local row = math.max(1, math.floor((lines - list_height - 3) / 2))
  local col = math.max(0, math.floor((columns - width) / 2))

  local input_buf = vim.api.nvim_create_buf(false, true)
  local list_buf = vim.api.nvim_create_buf(false, true)
  local input_win
  local list_win
  local closed = false

  local function close()
    if closed then
      return
    end
    closed = true

    for _, win in ipairs({ input_win, list_win }) do
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  end

  local function matches(item)
    if query == "" then
      return true
    end

    return format_item(item):lower():find(query:lower(), 1, true) ~= nil
  end

  local function refresh_items()
    filtered = vim.tbl_filter(matches, source_items)
    cursor = math.min(cursor, #filtered)
    if cursor < 1 then
      cursor = 1
    end

    top = math.min(top, cursor)
    if cursor >= top + list_height then
      top = cursor - list_height + 1
    end
    top = math.max(1, math.min(top, math.max(1, #filtered - list_height + 1)))
  end

  local function render()
    refresh_items()

    vim.api.nvim_set_option_value("modifiable", true, { buf = list_buf })
    vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)

    if #filtered == 0 then
      vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, { "  No results" })
      vim.api.nvim_buf_add_highlight(list_buf, ns, "Comment", 0, 0, -1)
    else
      local visible = {}
      for index = top, math.min(#filtered, top + list_height - 1) do
        local item = filtered[index]
        table.insert(visible, "  " .. format_item(item))
      end

      vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, visible)
      vim.api.nvim_buf_add_highlight(list_buf, ns, "PmenuSel", cursor - top, 0, -1)
    end

    vim.api.nvim_set_option_value("modifiable", false, { buf = list_buf })
    vim.api.nvim_set_option_value("modifiable", true, { buf = input_buf })
    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "> " .. query })
    vim.api.nvim_set_option_value("modifiable", false, { buf = input_buf })

    if input_win and vim.api.nvim_win_is_valid(input_win) then
      vim.api.nvim_set_current_win(input_win)
      vim.api.nvim_win_set_cursor(input_win, { 1, #query + 2 })
    end
  end

  local function select_current()
    local item = filtered[cursor]
    close()

    if item and on_select then
      on_select(item)
    end
  end

  local function move(delta)
    if #filtered == 0 then
      return
    end

    cursor = ((cursor - 1 + delta) % #filtered) + 1
    render()
  end

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = 1,
    border = "rounded",
    title = " " .. prompt .. " ",
    title_pos = "center",
    style = "minimal",
  })

  list_win = vim.api.nvim_open_win(list_buf, false, {
    relative = "editor",
    row = row + 3,
    col = col,
    width = width,
    height = list_height,
    border = "rounded",
    style = "minimal",
  })

  for _, win in ipairs({ input_win, list_win }) do
    vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat,FloatBorder:FloatBorder", { win = win })
  end

  for _, buf in ipairs({ input_buf, list_buf }) do
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  end

  local map_opts = { buffer = input_buf, nowait = true }
  vim.keymap.set("i", "<Esc>", close, map_opts)
  vim.keymap.set("i", "<C-c>", close, map_opts)
  vim.keymap.set("i", "<CR>", select_current, map_opts)
  vim.keymap.set("i", "<Down>", function()
    move(1)
  end, map_opts)
  vim.keymap.set("i", "<C-n>", function()
    move(1)
  end, map_opts)
  vim.keymap.set("i", "<Up>", function()
    move(-1)
  end, map_opts)
  vim.keymap.set("i", "<C-p>", function()
    move(-1)
  end, map_opts)
  vim.keymap.set("i", "<BS>", function()
    query = query:sub(1, -2)
    cursor = 1
    top = 1
    render()
  end, map_opts)
  vim.keymap.set("i", "<C-u>", function()
    query = ""
    cursor = 1
    top = 1
    render()
  end, map_opts)

  for char = 32, 126 do
    local key = vim.fn.nr2char(char)
    vim.keymap.set("i", key, function()
      query = query .. key
      cursor = 1
      top = 1
      render()
    end, map_opts)
  end

  render()
  vim.cmd("startinsert")
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

  open_select_picker({
    prompt = "Buffers",
    items = buffers,
    format_item = function(buffer)
      local modified = buffer.changed == 1 and " [+]" or ""
      return ("%d  %s%s"):format(buffer.bufnr, get_buffer_name(buffer.bufnr), modified)
    end,
    on_select = function(buffer)
      open_buffer(buffer.bufnr, target)
    end,
  })
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

  open_select_picker({
    prompt = "Help tags",
    items = tags,
    on_select = function(topic)
      if topic and topic ~= "" then
        open_help(topic, target)
      end
    end,
  })
end

local function tabs()
  local tabpages = vim.api.nvim_list_tabpages()

  open_select_picker({
    prompt = "Tabs",
    items = tabpages,
    format_item = function(tabpage)
      local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
      local wins = vim.api.nvim_tabpage_list_wins(tabpage)
      local bufnr = wins[1] and vim.api.nvim_win_get_buf(wins[1])
      local name = bufnr and get_buffer_name(bufnr) or "[No Name]"
      return ("%d  %s"):format(tabnr, name)
    end,
    on_select = function(tabpage)
      vim.api.nvim_set_current_tabpage(tabpage)
    end,
  })
end

local function sanitize_grep_text(value)
  if type(value) ~= "string" then
    return value
  end

  return value:gsub("%z", "")
end

local function patch_fff_grep_search()
  local ok, grep = pcall(require, "fff.grep")
  if not ok or grep._user_sanitize_nul_bytes then
    return
  end

  local search = grep.search
  grep.search = function(...)
    local result = search(...)

    for _, item in ipairs((result and result.items) or {}) do
      item.name = sanitize_grep_text(item.name)
      item.directory = sanitize_grep_text(item.directory)
      item.relative_path = sanitize_grep_text(item.relative_path)
      item.line_content = sanitize_grep_text(item.line_content)
    end

    return result
  end

  grep._user_sanitize_nul_bytes = true
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
    lazy = false,
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
      patch_fff_grep_search()
    end,
  },
}
