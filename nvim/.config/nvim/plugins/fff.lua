local function open_in_new_tab(callback)
  vim.cmd("tabnew")
  callback()
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
