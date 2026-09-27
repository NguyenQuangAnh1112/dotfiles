return {
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = "rktjmp/lush.nvim",
		lazy = false,
		priority = 1000,
		init = function()
			-- Bật trong suốt gốc của zenbones (cho Normal, SignColumn, LineNr, v.v.)
			vim.g.zenbones = {
				transparent_background = true,
			}
		end,
		config = function()
			-- Bổ sung trong suốt cho Float Window, Popup Menu và Status/Tabline
			local float_and_ui_groups = {
				"NormalFloat",
				"FloatTitle",
				"StatusLine",
				"StatusLineNC",
				"TabLine",
				"TabLineFill",
				"Pmenu",
				"PmenuKind",
				"PmenuExtra",
				"PmenuSbar",
			}

			local function apply_transparency()
				for _, group in ipairs(float_and_ui_groups) do
					local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
					hl.bg = "NONE"
					hl.ctermbg = "NONE"
					vim.api.nvim_set_hl(0, group, hl)
				end
			end

			-- Đăng ký hook ColorScheme để chạy đúng 1 lần khi theme tải, không bị ghi đè
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "*bones*",
				callback = apply_transparency,
			})

			vim.cmd("colorscheme zenbones")
		end,
	},
}
