local M = {}

local function count_path_parts(path)
  local count = 0
  for _ in path:gmatch("[^/]+") do
    count = count + 1
  end
  return count
end

local function get_target_score(target)
  local dir = vim.fs.dirname(target)
  local project_name = vim.fs.basename(dir)
  local target_name = vim.fn.fnamemodify(target, ":t:r")
  local score = count_path_parts(dir)

  if target_name == project_name then
    score = score - 100
  end

  if target:match("%.slnf$") then
    score = score - 50
  elseif target:match("%.sln$") then
    score = score - 30
  elseif target:match("%.slnx$") then
    score = score - 20
  end

  return score
end

function M.choose_target(targets)
  table.sort(targets, function(left, right)
    local left_score = get_target_score(left)
    local right_score = get_target_score(right)

    if left_score == right_score then
      return left < right
    end

    return left_score < right_score
  end)

  return targets[1]
end

local cached_roslyn_cmd = nil
function M.get_cmd()
  if cached_roslyn_cmd then
    return cached_roslyn_cmd
  end

  local dotnet = vim.fn.expand("~/.dotnet/dotnet")
  if vim.fn.executable(dotnet) == 0 then
    dotnet = "dotnet"
  end

  local package_path = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "roslyn")
  if vim.fn.isdirectory(package_path) == 0 then
    package_path = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "roslyn-language-server")
  end
  local dlls = vim.fs.find("Microsoft.CodeAnalysis.LanguageServer.dll", {
    path = package_path,
    type = "file",
    limit = 1,
  })

  if dlls[1] then
    cached_roslyn_cmd = {
      dotnet,
      dlls[1],
      "--logLevel",
      "Warning",
      "--extensionLogDirectory",
      vim.fs.joinpath(vim.fn.stdpath("cache"), "roslyn_ls", "logs"),
      "--stdio",
    }
  else
    cached_roslyn_cmd = { "roslyn-language-server", "--stdio" }
  end

  return cached_roslyn_cmd
end

function M.get_commands()
  local ok, cmds = pcall(require, "roslyn.lsp.commands")
  return ok and cmds or {}
end

function M.get_handlers()
  local ok, handlers = pcall(require, "roslyn.lsp.handlers")
  return ok and handlers or {}
end

function M.get_server_opts()
  return {
    cmd = M.get_cmd(),
    cmd_env = {
      DOTNET_ROOT = vim.fn.expand("~/.dotnet"),
      DOTNET_TieredPGO = "1",
      DOTNET_TC_QuickJitForLoops = "1",
      DOTNET_ReadyToRun = "1",
      DOTNET_CLI_TELEMETRY_OPTOUT = "1",
      DOTNET_MULTILEVEL_LOOKUP = "0",
    },
    commands = M.get_commands(),
    handlers = M.get_handlers(),
    settings = {
      ["csharp|background_analysis"] = {
        dotnet_analyzer_diagnostics_scope = "openFiles",
        dotnet_compiler_diagnostics_scope = "openFiles",
      },
      ["csharp|completion"] = {
        dotnet_show_completion_items_from_unimported_namespaces = true,
        dotnet_show_name_completion_suggestions = true,
      },
      ["csharp|formatting"] = {
        dotnet_organize_imports_on_format = true,
      },
      ["csharp|inlay_hints"] = {
        csharp_enable_inlay_hints_for_implicit_object_creation = true,
        csharp_enable_inlay_hints_for_implicit_variable_types = true,
        csharp_enable_inlay_hints_for_lambda_parameter_types = true,
        csharp_enable_inlay_hints_for_types = true,
        dotnet_enable_inlay_hints_for_indexer_parameters = true,
        dotnet_enable_inlay_hints_for_literal_parameters = true,
        dotnet_enable_inlay_hints_for_object_creation_parameters = true,
        dotnet_enable_inlay_hints_for_other_parameters = true,
        dotnet_enable_inlay_hints_for_parameters = true,
        dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
        dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
        dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
      },
      ["csharp|symbol_search"] = {
        dotnet_search_reference_assemblies = false,
      },
    },
  }
end

setmetatable(M, {
  __index = function(t, key)
    if key == "commands" then
      return t.get_commands()
    elseif key == "handlers" then
      return t.get_handlers()
    elseif key == "server_opts" then
      return t.get_server_opts()
    end
  end,
})

return M
