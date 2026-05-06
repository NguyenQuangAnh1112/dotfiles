vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local config_path = vim.fn.stdpath("config")

dofile(config_path .. "/config/options.lua")
dofile(config_path .. "/config/keymaps.lua")
dofile(config_path .. "/config/fcitx5.lua")
dofile(config_path .. "/config/lazy.lua")

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local argc = vim.fn.argc()

		if argc == 1 then
			local arg = vim.fn.argv(0)
			if vim.fn.isdirectory(arg) == 1 then
				vim.schedule(function()
					vim.cmd("Oil " .. vim.fn.fnameescape(arg))
				end)
			end
			return
		end

		if argc > 1 then
			return
		end

		if vim.bo[0].buftype ~= "" or vim.api.nvim_buf_get_name(0) ~= "" then
			return
		end

		vim.schedule(function()
			vim.cmd("Oil")
		end)
	end,
})
