return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		config = function(_, opts)
			require("flash").setup(opts)

			local function set_flash_colors()
				-- Đổi màu chữ trắng nổi bật trên nền đen xám
				vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#ffffff", bg = "#000000", bold = true })
			end

			set_flash_colors()
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = set_flash_colors,
			})
		end,
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"<S-Tab>",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
}
