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
        use_nvim_cmp_as_default = true,
      },
      completion = {
        trigger = {
          prefetch_on_insert = false,
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
            treesitter = { "lsp" },
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
      },
      sources = {
        default = { "lsp", "snippets", "buffer", "path" },
        providers = {
          lsp = {
            name = "LSP",
            async = true,
            max_items = 8,
            min_keyword_length = 1,
          },
          path = {
            name = "Path",
            score_offset = 3,
            max_items = 4,
          },
          snippets = {
            name = "Snip",
            score_offset = 1,
            max_items = 4,
          },
          buffer = {
            name = "Buf",
            min_keyword_length = 2,
            max_items = 6,
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
    opts_extend = { "sources.default" },
  },
}
