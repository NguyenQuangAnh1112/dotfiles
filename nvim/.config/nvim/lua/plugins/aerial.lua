return {
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
		keys = {
			{ "<leader>o", "<cmd>AerialToggle! left<CR>", desc = "Toggle Code Outline (Aerial)" },
			{ "<leader>O", "<cmd>AerialNavToggle<CR>", desc = "Toggle Floating Outline (Nav)" },
			{
				"[s",
				function()
					require("aerial").prev()
				end,
				desc = "Previous symbol (Aerial)",
			},
			{
				"]s",
				function()
					require("aerial").next()
				end,
				desc = "Next symbol (Aerial)",
			},
		},
		opts = {
			backends = { "lsp", "treesitter" },
			layout = {
				width = 34,
				default_direction = "left",
				placement = "window",
			},
			attach_mode = "global",
			show_guides = true,
			guides = {
				mid_item = "├─",
				last_item = "└─",
				nested_top = "│ ",
				whitespace = "  ",
			},
			filter_kind = false, -- Hiển thị đầy đủ class, method, function, field...
			highlight_on_jump = 250,
			close_on_select = false,
		},
	},
}
