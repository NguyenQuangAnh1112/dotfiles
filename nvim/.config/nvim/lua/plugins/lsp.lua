return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog", "MasonUninstall" },
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "clangd",
        "gdscript-formatter",
        "lua-language-server",
        "pyrefly",
        "roslyn",
        "ruff",
        "slang",
        "stylua",
      },
    },
  },
  {
    "seblyng/roslyn.nvim",
    ft = { "cs" },
    opts = function()
      local roslyn = require("config.lsp.roslyn")
      return {
        filewatching = "roslyn",
        choose_target = roslyn.choose_target,
        broad_search = false,
        lock_target = true,
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      local roslyn = require("config.lsp.roslyn")
      local godot = require("config.lsp.godot")
      local defs = require("config.lsp.definition")

      vim.diagnostic.config({
        underline = false,
        severity_sort = true,
      })

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      for cmd_name, cmd_fn in pairs(roslyn.commands) do
        vim.lsp.commands[cmd_name] = cmd_fn
      end

      local servers = {
        pyrefly = {
          cmd = { "pyrefly", "lsp" },
          filetypes = { "python" },
          root_markers = { "pyrefly.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
          settings = {
            pyrefly = {
              typeCheckingMode = "basic",
            },
          },
        },
        ruff = {},
        gdscript = {
          root_dir = godot.get_root_dir,
        },
        roslyn = roslyn.server_opts,
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                },
              },
              completion = {
                callSnippet = "Replace",
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            -- "--clang-tidy",
            "--header-insertion=never",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          root_markers = { "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", ".git" },
        },
      }

      for server, opts in pairs(servers) do
        opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
        vim.lsp.config(server, opts)

        if server ~= "roslyn" then
          vim.lsp.enable(server)
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local keymap = vim.keymap.set
          local opts = { buffer = event.buf }

          keymap("n", "gd", defs.open_in_new_tab, opts)
          keymap("n", "td", defs.open_in_tmux, opts)
          keymap("n", "gD", vim.lsp.buf.declaration, opts)
          keymap("n", "gr", vim.lsp.buf.references, opts)
          keymap("n", "gi", vim.lsp.buf.implementation, opts)
          keymap("n", "K", vim.lsp.buf.hover, opts)
          keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
          keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          keymap("n", "<leader>lr", "<cmd>LspRestart<CR>", vim.tbl_extend("force", opts, { desc = "Restart LSP" }))
          keymap("n", "<leader>f", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, opts)

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "roslyn" then
            keymap("n", "<leader>lt", "<cmd>Roslyn target<CR>", vim.tbl_extend("force", opts, { desc = "Select Roslyn target" }))

            if vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled() then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
          end
        end,
      })
    end,
  },
}
