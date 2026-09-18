local keymap = vim.keymap.set

local diagnostics_float_win

local function replace_in_selection()
	local start_pos = vim.api.nvim_buf_get_mark(0, "<")
	local end_pos = vim.api.nvim_buf_get_mark(0, ">")

	if start_pos[1] == 0 or end_pos[1] == 0 then
		vim.notify("No visual selection found", vim.log.levels.WARN)
		return
	end

	local line_start = math.min(start_pos[1], end_pos[1])
	local line_end = math.max(start_pos[1], end_pos[1])

	local find = vim.fn.input("Find: ")
	if find == nil or find == "" then
		return
	end

	local replace = vim.fn.input("Replace: ")
	if replace == nil then
		return
	end

	local find_escaped = vim.fn.escape(find, [[\/]])
	local replace_escaped = vim.fn.escape(replace, [[\/&]])
	vim.cmd(([[silent %d,%ds/\V%s/%s/g]]):format(line_start, line_end, find_escaped, replace_escaped))
end

local function show_line_diagnostics(line)
	if diagnostics_float_win and vim.api.nvim_win_is_valid(diagnostics_float_win) then
		if vim.api.nvim_get_current_win() ~= diagnostics_float_win then
			vim.api.nvim_set_current_win(diagnostics_float_win)
		end
		return
	end

	line = line or (vim.api.nvim_win_get_cursor(0)[1] - 1)
	local diagnostics = vim.diagnostic.get(0, { lnum = line })

	if vim.tbl_isempty(diagnostics) then
		vim.notify("No diagnostics on current line", vim.log.levels.INFO)
		return
	end

	local _, winid = vim.diagnostic.open_float(0, {
		scope = "line",
		border = "rounded",
		focusable = true,
		source = "always",
		close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufHidden" },
	})

	diagnostics_float_win = winid
end

local function toggle_markdown_checkbox()
	if vim.bo.filetype ~= "markdown" then
		vim.notify("Not a markdown buffer", vim.log.levels.WARN)
		return
	end

	local line = vim.api.nvim_get_current_line()

	if line:find("%[ %]") then
		local updated = line:gsub("%[ %]", "[x]", 1)
		vim.api.nvim_set_current_line(updated)
		return
	end

	if line:find("%[[xX]%]") then
		local updated = line:gsub("%[[xX]%]", "[ ]", 1)
		vim.api.nvim_set_current_line(updated)
		return
	end

	vim.notify("No checkbox found on current line", vim.log.levels.INFO)
end

local function close_all_methods()
	local bufnr = vim.api.nvim_get_current_buf()
	local target_level = 1
	local max_lines = math.min(40, vim.api.nvim_buf_line_count(bufnr))
	for i = 1, max_lines do
		local line = vim.fn.getline(i)
		if line:match("^%s*namespace%s+") then
			target_level = 2
			break
		end
	end
	vim.wo.foldlevel = target_level
end

local function smart_toggle_fold()
	if vim.fn.foldclosed(".") ~= -1 then
		pcall(vim.cmd, "normal! zO")
	else
		pcall(vim.cmd, "normal! zc")
	end
end

for i = 1, 9 do
	keymap("n", ("<leader>%d"):format(i), ("<cmd>tabnext %d<CR>"):format(i), {
		desc = ("Go to tab %d"):format(i),
	})
end

keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")
keymap("n", "<leader><leader>", "zz", { desc = "Center cursor line" })
keymap("n", "<C-e>", "<C-e>j", { desc = "Scroll down and move cursor down" })
keymap("n", "<C-y>", "<C-y>k", { desc = "Scroll up and move cursor up" })

keymap("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })
keymap("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all (force)" })
keymap("n", "<leader>e", show_line_diagnostics, { desc = "Show line diagnostics" })
keymap("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap("x", "<leader>rv", replace_in_selection, { desc = "Replace in selection" })

keymap("n", "<leader>sv", "<cmd>vsplit<CR><cmd>Oil<CR>", { desc = "Vsplit and open Oil" })
keymap("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split horizontally" })
keymap("n", "<leader>\\", "<cmd>vsplit<CR><cmd>terminal<CR>", { desc = "Vsplit and open terminal" })
keymap("n", "<leader>rr", function() require("config.runner").run() end, { desc = "Run file or project in new tab" })

keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })

keymap("n", "z<Space>", close_all_methods, { desc = "Close all methods (keep class open)" })
keymap("n", "za", smart_toggle_fold, { desc = "Toggle fold (open recursively in one shot)" })
keymap("x", "zf", function()
	vim.opt_local.foldmethod = "manual"
	vim.cmd("normal! zf")
end, { desc = "Create manual fold from selection" })

local checkbox_group = vim.api.nvim_create_augroup("user-markdown-checkbox", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = checkbox_group,
	pattern = "markdown",
	callback = function(args)
		vim.keymap.set("n", "<leader>x", toggle_markdown_checkbox, {
			buffer = args.buf,
			desc = "Toggle markdown checkbox",
		})
	end,
})
