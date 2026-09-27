vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.fcitx5")
require("config.lazy")

-- Load built-in packs after lazy.nvim so lazy doesn't strip them from runtimepath
pcall(vim.cmd.packadd, "cfilter")

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 and vim.bo[0].buftype == "" and vim.api.nvim_buf_get_name(0) == "" then
			vim.schedule(function()
				local ok, fff = pcall(require, "fff")
				if ok then
					fff.find_files()
				end
			end)
		end
	end,
})
