return {
	{
		"kevinhwang91/nvim-hlslens",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("hlslens").setup({
				calm_down = true, -- Tự động tắt lens khi di chuyển con trỏ ra khỏi kết quả
			})

			local kopts = { noremap = true, silent = true }

			-- Tích hợp lens vào các phím nhảy tìm kiếm
			vim.keymap.set(
				"n",
				"n",
				[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
				kopts
			)
			vim.keymap.set(
				"n",
				"N",
				[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
				kopts
			)
			vim.keymap.set("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
			vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
			vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
			vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
		end,
	},
}
