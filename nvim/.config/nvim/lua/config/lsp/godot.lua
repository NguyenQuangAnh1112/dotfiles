local M = {}

local godot_lsp_port = tonumber(vim.env.GDScript_Port) or 6005
local godot_lsp_addr = ("127.0.0.1:%d"):format(godot_lsp_port)
local godot_lsp_unavailable_notified = false

function M.is_available()
  local ok, channel = pcall(vim.fn.sockconnect, "tcp", godot_lsp_addr, { rpc = false })
  if ok and channel > 0 then
    vim.fn.chanclose(channel)
    return true
  end
  return false
end

function M.get_project_root(bufnr)
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

function M.get_root_dir(bufnr, on_dir)
  local project_root = M.get_project_root(bufnr)
  if not project_root then
    return
  end

  if M.is_available() then
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

return M
