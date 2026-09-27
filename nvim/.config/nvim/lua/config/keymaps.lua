local keymap = vim.keymap.set

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
keymap("n", "<leader>e", function()
	vim.diagnostic.open_float({ border = "rounded", scope = "line" })
end, { desc = "Show line diagnostics" })
keymap("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap("x", "<leader>rv", replace_in_selection, { desc = "Replace in selection" })

-- Visual mode enhancements
keymap("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
keymap("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })
keymap("x", "<", "<gv", { desc = "Indent left and keep selection" })
keymap("x", ">", ">gv", { desc = "Indent right and keep selection" })
keymap("x", "p", [["_dP]], { desc = "Paste over without overwriting register" })

keymap("n", "<leader>u", function()
	pcall(vim.cmd.packadd, "nvim.undotree")
	local ok, undotree = pcall(require, "undotree")
	if ok then
		undotree.open()
	else
		vim.cmd("Undotree")
	end
end, { desc = "Toggle UndoTree" })

-- LSP Diagnostic navigation (Nhảy giữa các lỗi đỏ/vàng trong file code)
keymap("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
keymap("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
keymap("n", "]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true }) end, { desc = "Next error" })
keymap("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end, { desc = "Previous error" })

-- Quickfix list navigation & toggle (An toàn, tự quay vòng, thông báo nếu rỗng)
local function qf_next()
	local qf = vim.fn.getqflist()
	if #qf == 0 then
		vim.notify("Quickfix list đang trống (nếu muốn nhảy lỗi code trong file, hãy dùng ]d / [d)", vim.log.levels.WARN)
		return
	end
	local ok = pcall(vim.cmd, "cnext")
	if not ok then
		pcall(vim.cmd, "cfirst")
	end
	vim.cmd("normal! zz")
end

local function qf_prev()
	local qf = vim.fn.getqflist()
	if #qf == 0 then
		vim.notify("Quickfix list đang trống (nếu muốn nhảy lỗi code trong file, hãy dùng ]d / [d)", vim.log.levels.WARN)
		return
	end
	local ok = pcall(vim.cmd, "cprev")
	if not ok then
		pcall(vim.cmd, "clast")
	end
	vim.cmd("normal! zz")
end

local function toggle_quickfix()
	local qf_open = false
	for _, win in ipairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			qf_open = true
			break
		end
	end
	if qf_open then
		vim.cmd("cclose")
	else
		local qf = vim.fn.getqflist()
		if #qf == 0 then
			vim.notify("Quickfix list đang trống", vim.log.levels.INFO)
		end
		vim.cmd("botright copen 10")
	end
end

keymap("n", "]q", qf_next, { desc = "Next quickfix item" })
keymap("n", "[q", qf_prev, { desc = "Previous quickfix item" })
keymap("n", "<leader>co", toggle_quickfix, { desc = "Toggle Quickfix window" })

-- Toggle LSP Inlay Hints (Persistent & Global)
if vim.lsp.inlay_hint then
	local state_file = vim.fs.joinpath(vim.fn.stdpath("state"), "inlay_hint")

	local function get_saved_state()
		local f = io.open(state_file, "r")
		if not f then
			return false
		end
		local content = f:read("*a")
		f:close()
		return vim.trim(content) == "1"
	end

	local function save_state(enabled)
		local dir = vim.fs.dirname(state_file)
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
		local f = io.open(state_file, "w")
		if f then
			f:write(enabled and "1" or "0")
			f:close()
		end
	end

	local function set_inlay_hint(enabled)
		vim.lsp.inlay_hint.enable(enabled)
		save_state(enabled)
		vim.notify("Inlay hints: " .. (enabled and "ON" or "OFF"), vim.log.levels.INFO)
	end

	vim.lsp.inlay_hint.enable(get_saved_state())

	keymap("n", "<leader>th", function()
		set_inlay_hint(not vim.lsp.inlay_hint.is_enabled())
	end, { desc = "Toggle LSP Inlay Hints (Global & Persistent)" })

	vim.api.nvim_create_user_command("InlayHints", function(opts)
		local arg = vim.trim(opts.args):lower()
		if arg == "on" or arg == "enable" then
			set_inlay_hint(true)
		elseif arg == "off" or arg == "disable" then
			set_inlay_hint(false)
		elseif arg == "toggle" or arg == "" then
			set_inlay_hint(not vim.lsp.inlay_hint.is_enabled())
		else
			vim.notify("Usage: :InlayHints [on|off|toggle]", vim.log.levels.WARN)
		end
	end, {
		nargs = "?",
		complete = function()
			return { "on", "off", "toggle" }
		end,
		desc = "Set or toggle LSP Inlay Hints (global & persistent)",
	})
end


keymap("n", "<leader>sv", "<cmd>vsplit<CR><cmd>Oil<CR>", { desc = "Vsplit and open Oil" })
keymap("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split horizontally" })
keymap("n", "<leader>\\", "<cmd>vsplit<CR><cmd>terminal<CR>", { desc = "Vsplit and open terminal" })
keymap("n", "<leader>rr", function() require("config.runner").run() end, { desc = "Run file or project in new tab" })

local function open_lazygit()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.9)
	local height = math.floor(vim.o.lines * 0.9)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
	})

	vim.fn.termopen("lazygit", {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
	vim.cmd("startinsert")
end
keymap("n", "<leader>gg", open_lazygit, { desc = "Open LazyGit" })

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
