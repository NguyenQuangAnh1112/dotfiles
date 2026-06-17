local function format_lsp_progress(msg)
  local message = msg.message or (msg.done and "Completed" or "In progress...")

  local percentage = msg.percentage
  if msg.done and percentage == nil then
    percentage = 100
  end

  if type(percentage) == "number" then
    percentage = math.max(0, math.min(100, percentage))
    local width = 12
    local filled = math.floor((percentage / 100) * width + 0.5)
    local bar = string.rep("█", filled) .. string.rep("░", width - filled)
    return string.format("[%s] %3.0f%% %s", bar, percentage, message)
  end

  if type(percentage) == "string" then
    return string.format("[%s] %s %s", percentage, percentage, message)
  end

  return message
end

return {
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        display = {
          progress_icon = { pattern = "dots", period = 1 },
          done_icon = "✓",
          format_message = format_lsp_progress,
        },
      },
      notification = {
        window = {
          winblend = 0,
        },
      },
    },
  },
}
