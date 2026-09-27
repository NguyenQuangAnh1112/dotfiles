local M = {}

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

function M.open_in_new_tab()
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

function M.open_in_tmux()
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

return M
