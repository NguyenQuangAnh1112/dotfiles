if vim.fn.executable("fcitx5-remote") ~= 1 then
  return
end

local group = vim.api.nvim_create_augroup("user-fcitx5", { clear = true })

local function set_us_layout()
  if vim.system then
    vim.system({ "fcitx5-remote", "-s", "keyboard-us" })
  else
    vim.fn.system({ "fcitx5-remote", "-s", "keyboard-us" })
  end
end

vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
  group = group,
  callback = set_us_layout,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = set_us_layout,
})
