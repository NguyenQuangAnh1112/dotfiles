local function get_completion_item_key(item)
  local text_edit = item.textEdit
  local new_text = text_edit and text_edit.newText

  return table.concat({
    tostring(item.kind or ""),
    new_text or item.textEditText or item.insertText or item.label or "",
  }, "|")
end

local function dedupe_completion_items(items)
  local deduped = {}
  local seen = {}

  for _, item in ipairs(items) do
    local key = get_completion_item_key(item)
    if not seen[key] then
      seen[key] = true
      table.insert(deduped, item)
    end
  end

  return deduped
end

local ignored_buffer_path_patterns = {
  "/%.local/share/nvim/",
  "/node_modules/",
  "/%.venv/",
  "/venv/",
  "/site%-packages/",
  "/dist/",
  "/build/",
  "/target/",
}

local max_buffer_source_lines = 2000

local function is_ignored_buffer_path(path)
  for _, pattern in ipairs(ignored_buffer_path_patterns) do
    if path:match(pattern) then
      return true
    end
  end

  return false
end

local function is_buffer_completion_candidate(bufnr, filetype)
  if not vim.api.nvim_buf_is_loaded(bufnr) or vim.fn.buflisted(bufnr) == 0 then
    return false
  end

  if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype ~= filetype then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" and is_ignored_buffer_path(name) then
    return false
  end

  return vim.api.nvim_buf_line_count(bufnr) <= max_buffer_source_lines
end

local function get_buffer_completion_bufnrs()
  local current_buf = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[current_buf].filetype
  if filetype == "" or not is_buffer_completion_candidate(current_buf, filetype) then
    return {}
  end

  local bufnrs = {}

  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if is_buffer_completion_candidate(info.bufnr, filetype) then
      table.insert(bufnrs, info.bufnr)
    end
  end

  return bufnrs
end

return {
  {
    "saghen/blink.cmp",
    version = "v0.*",
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = { "select_and_accept", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        trigger = {
          prefetch_on_insert = true,
        },
        list = {
          max_items = 8,
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        menu = {
          border = "rounded",
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 120,
          update_delay_ms = 80,
          treesitter_highlighting = true,
          window = { border = "rounded" },
        },
        ghost_text = {
          enabled = false,
        },
      },
      signature = {
        enabled = false,
        trigger = {
          enabled = true,
          show_on_insert_on_trigger_character = false,
        },
        window = {
          border = "rounded",
          treesitter_highlighting = false,
          show_documentation = false,
        },
      },
      sources = {
        default = { "lsp", "buffer", "path" },
        providers = {
          lsp = {
            name = "LSP",
            async = true,
            transform_items = function(_, items)
              items = vim.tbl_filter(function(item)
                return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
              end, items)

              return dedupe_completion_items(items)
            end,
            max_items = 8,
            min_keyword_length = 1,
          },
          path = {
            name = "Path",
            score_offset = 3,
            max_items = 4,
          },
          buffer = {
            name = "Buf",
            min_keyword_length = 2,
            max_items = 6,
            enabled = function()
              return not vim.tbl_isempty(get_buffer_completion_bufnrs())
            end,
            transform_items = function(_, items)
              return dedupe_completion_items(items)
            end,
            opts = {
              get_bufnrs = get_buffer_completion_bufnrs,
            },
          },
        },
      },
      cmdline = {
        enabled = true,
        keymap = {
          preset = "cmdline",
        },
        sources = function()
          local cmdtype = vim.fn.getcmdtype()

          if cmdtype == "/" or cmdtype == "?" then
            return { "buffer" }
          end

          if cmdtype == ":" or cmdtype == "@" then
            return { "cmdline" }
          end

          return {}
        end,
        completion = {
          ghost_text = {
            enabled = false,
          },
        },
      },
    },
    config = function(_, opts)
      require("blink.cmp").setup(opts)

      local groups = {
        "BlinkCmpMenu",
        "BlinkCmpMenuBorder",
        "BlinkCmpDoc",
        "BlinkCmpDocBorder",
        "BlinkCmpSignatureHelp",
        "BlinkCmpSignatureHelpBorder",
        "BlinkCmpScrollBarThumb",
        "BlinkCmpScrollBarGutter",
        "Pmenu",
        "PmenuKind",
        "PmenuExtra",
        "PmenuSbar",
        "PmenuThumb",
      }

      local function set_blink_hl()
        for _, group in ipairs(groups) do
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
          if ok then
            hl.bg = "none"
            hl.ctermbg = "none"
            vim.api.nvim_set_hl(0, group, hl)
          end
        end

        vim.api.nvim_set_hl(0, "PmenuSel", { fg = "#0b1020", bg = "#ffd166", bold = true, nocombine = true, blend = 0 })
        vim.api.nvim_set_hl(
          0,
          "BlinkCmpMenuSelection",
          { fg = "#0b1020", bg = "#ffd166", bold = true, nocombine = true }
        )
        vim.api.nvim_set_hl(0, "BlinkCmpMenuSelectionBorder", { fg = "#ffd166", bg = "none", bold = true, nocombine = true })
      end

      set_blink_hl()

      local group = vim.api.nvim_create_augroup("user-blink-selection-hl", { clear = true })

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          vim.schedule(set_blink_hl)
        end,
      })
    end,
    opts_extend = { "sources.default" },
  },
}
