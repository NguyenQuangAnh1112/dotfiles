vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local config_path = vim.fn.stdpath("config")

dofile(config_path .. "/config/options.lua")
dofile(config_path .. "/config/keymaps.lua")
dofile(config_path .. "/config/commands.lua")
dofile(config_path .. "/config/fcitx5.lua")
dofile(config_path .. "/config/lazy.lua")

local function open_fff_on_start(directory)
	vim.schedule(function()
		if directory then
			vim.cmd("cd " .. vim.fn.fnameescape(directory))
		end

		local ok, fff = pcall(require, "fff")
		if ok then
			fff.find_files()
		else
			vim.notify("fff.nvim is not available", vim.log.levels.ERROR)
		end
	end)
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local argc = vim.fn.argc()

		if argc == 1 then
			local arg = vim.fn.argv(0)
			if vim.fn.isdirectory(arg) == 1 then
				open_fff_on_start(arg)
			end
			return
		end

		if argc > 1 then
			return
		end

		if vim.bo[0].buftype ~= "" or vim.api.nvim_buf_get_name(0) ~= "" then
			return
		end

		open_fff_on_start()
	end,
})
