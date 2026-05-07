return {
  {
    "LuaCATS/love2d",
    lazy = true,
  },
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "basedpyright",
        "lua_ls",
      },
      automatic_installation = true,
      automatic_enable = false,
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    opts = {
      ensure_installed = {
        "gdscript-formatter",
        "ruff",
        "stylua",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        underline = false,
        severity_sort = true,
      })

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      local function get_definition_location()
        local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" })
        if vim.tbl_isempty(clients) then
          vim.notify("No definition provider attached", vim.log.levels.WARN)
          return nil
        end

        local params = vim.lsp.util.make_position_params()
        local responses = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 1000)

        if not responses or vim.tbl_isempty(responses) then
          vim.notify("No definition found", vim.log.levels.WARN)
          return nil
        end

        local location
        for _, response in pairs(responses) do
          if response.result then
            if vim.islist(response.result) then
              location = response.result[1]
            else
              location = response.result
            end
          end

          if location then
            break
          end
        end

        if not location then
          vim.notify("No definition found", vim.log.levels.WARN)
          return nil
        end

        return location
      end

      local function get_location_target(location)
        local uri = location.uri or location.targetUri
        local range = location.range or location.targetSelectionRange

        if not uri or not range then
          vim.notify("Definition location is invalid", vim.log.levels.ERROR)
          return nil
        end

        return {
          file = vim.uri_to_fname(uri),
          line = range.start.line + 1,
          col = range.start.character,
        }
      end

      local function open_definition_in_new_tab()
        local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" })
        if vim.tbl_isempty(clients) then
          vim.notify("No definition provider attached", vim.log.levels.WARN)
          return
        end

        vim.lsp.buf.definition({
          on_list = function(result)
            local item = result.items[1]
            if not item then
              vim.notify("No definition found", vim.log.levels.WARN)
              return
            end

            vim.cmd("tabnew")
            vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
            vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
            vim.cmd("normal! zv")
          end,
        })
      end

      local function open_definition_in_tmux()
        if not vim.env.TMUX or vim.env.TMUX == "" then
          vim.notify("gtd requires running inside tmux", vim.log.levels.ERROR)
          return
        end

        local location = get_definition_location()
        if not location then
          return
        end

        local target = get_location_target(location)
        if not target then
          return
        end

        local cmd = table.concat({
          "nvim",
          vim.fn.shellescape(("+call cursor(%d,%d)"):format(target.line, target.col + 1)),
          vim.fn.shellescape(target.file),
        }, " ")

        local job_id = vim.fn.jobstart({ "tmux", "new-window", "-c", vim.fn.getcwd(), cmd }, { detach = true })
        if job_id <= 0 then
          vim.notify("Failed to open tmux window", vim.log.levels.ERROR)
        end
      end

      local love2d_library = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "love2d", "library")
      local godot_lsp_port = tonumber(vim.env.GDScript_Port) or 6005
      local godot_lsp_addr = ("127.0.0.1:%d"):format(godot_lsp_port)
      local godot_lsp_unavailable_notified = false

      local function is_godot_lsp_available()
        local ok, channel = pcall(vim.fn.sockconnect, "tcp", godot_lsp_addr, { rpc = false })
        if ok and channel > 0 then
          vim.fn.chanclose(channel)
          return true
        end

        return false
      end

      local function get_godot_project_root(bufnr)
        local file = vim.api.nvim_buf_get_name(bufnr)
        if file == "" then
          return nil
        end

        local project_files = vim.fs.find("project.godot", {
          path = vim.fs.dirname(file),
          upward = true,
          type = "file",
        })
        if project_files[1] then
          return vim.fs.dirname(project_files[1])
        end
      end

      local function get_godot_root_dir(bufnr, on_dir)
        local project_root = get_godot_project_root(bufnr)
        if not project_root then
          return
        end

        if is_godot_lsp_available() then
          on_dir(project_root)
          return
        end

        if not godot_lsp_unavailable_notified then
          vim.notify(
            ("Godot LSP is not running at %s; open the project in Godot first"):format(godot_lsp_addr),
            vim.log.levels.INFO
          )
          godot_lsp_unavailable_notified = true
        end
      end

      local servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic",
                diagnosticSeverityOverrides = {
                  reportMissingTypeStubs = "none",
                  reportUnusedImport = "none",
                  reportUnusedVariable = "none",
                },
              },
            },
          },
        },
        ruff = {},
        gdscript = {
          root_dir = get_godot_root_dir,
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim", "love" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  love2d_library,
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
      }

      for server, opts in pairs(servers) do
        opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
        vim.lsp.config(server, opts)
        vim.lsp.enable(server)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local keymap = vim.keymap.set
          local opts = { buffer = event.buf }

          keymap("n", "gd", open_definition_in_new_tab, opts)
          keymap("n", "td", open_definition_in_tmux, opts)
          keymap("n", "gD", vim.lsp.buf.declaration, opts)
          keymap("n", "gr", vim.lsp.buf.references, opts)
          keymap("n", "gi", vim.lsp.buf.implementation, opts)
          keymap("n", "K", vim.lsp.buf.hover, opts)
          keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
          keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          keymap("n", "<leader>f", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, opts)
        end,
      })
    end,
  },
}
