return {
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = "rktjmp/lush.nvim",
		lazy = false,
		priority = 1000,
		init = function()
			vim.g.zenbones = {
				transparent_background = true,
			}
		end,
		config = function()
			vim.cmd("colorscheme zenbones")

			local function apply_transparency()
				local transparent_groups = {
					"Normal",
					"NormalNC",
					"NormalFloat",
					"FloatBorder",
					"FloatTitle",
					"SignColumn",
					"EndOfBuffer",
					"TabLine",
					"TabLineFill",
					"TabLineSel",
					"WinSeparator",
					"LineNr",
					"CursorLineNr",
					"FoldColumn",
					"Pmenu",
					"PmenuKind",
					"PmenuExtra",
					"PmenuSbar",
					"StatusLine",
					"StatusLineNC",
				}

				for _, group in ipairs(transparent_groups) do
					local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
					hl.bg = "NONE"
					hl.ctermbg = "NONE"
					vim.api.nvim_set_hl(0, group, hl)
				end
			end

			apply_transparency()

			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "*bones*",
				callback = apply_transparency,
			})
		end,
	},
}
