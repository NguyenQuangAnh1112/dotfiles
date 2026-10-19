return {
	{
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		event = "VeryLazy",
		config = function()
			local mc = require("multicursor-nvim")
			mc.setup()

			local set = vim.keymap.set

			-- Thêm / bỏ qua con trỏ theo từ hoặc vùng chọn (tương tự Ctrl+D)
			set({ "n", "x" }, "<C-n>", function()
				mc.matchAddCursor(1)
			end, { desc = "Add cursor to next match" })
			set({ "n", "x" }, "<C-s>", function()
				mc.matchSkipCursor(1)
			end, { desc = "Skip next match" })
			set({ "n", "x" }, "<C-p>", function()
				mc.matchAddCursor(-1)
			end, { desc = "Add cursor to prev match" })

			-- Thêm con trỏ theo hàng dọc trên / dưới
			set({ "n", "x" }, "<C-Down>", function()
				mc.lineAddCursor(1)
			end, { desc = "Add cursor below" })
			set({ "n", "x" }, "<C-Up>", function()
				mc.lineAddCursor(-1)
			end, { desc = "Add cursor above" })

			-- Bật / tắt tất cả các con trỏ phụ
			set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Toggle cursors" })

			-- Thêm / xoá con trỏ bằng Ctrl + click chuột
			set("n", "<C-LeftMouse>", mc.handleMouse, { desc = "Add/remove cursor with mouse" })

			-- Keymap layer: Chỉ áp dụng khi đang có nhiều con trỏ hoạt động
			mc.addKeymapLayer(function(layerSet)
				-- Nhảy qua lại giữa các con trỏ
				layerSet({ "n", "x" }, "<Left>", mc.prevCursor)
				layerSet({ "n", "x" }, "<Right>", mc.nextCursor)

				-- Xoá con trỏ chính hiện tại
				layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

				-- Nhấn Esc để xoá các con trỏ phụ, quay về con trỏ đơn
				layerSet({ "n", "x" }, "<Esc>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					elseif mc.hasCursors() then
						mc.clearCursors()
					end
				end)
			end)
		end,
	},
}
