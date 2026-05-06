local keymap = vim.keymap.set

local diagnostics_float_win

local function find_available_executable(candidates)
	for _, candidate in ipairs(candidates) do
		if vim.fn.executable(candidate) == 1 then
			return candidate
		end
	end
end

local function looks_like_love_project(project_dir)
	local conf_path = vim.fs.joinpath(project_dir, "conf.lua")
	if vim.fn.filereadable(conf_path) == 1 then
		return true
	end

	local main_path = vim.fs.joinpath(project_dir, "main.lua")
	if vim.fn.filereadable(main_path) == 0 then
		return false
	end

	local main_contents = table.concat(vim.fn.readfile(main_path), "\n")
	return main_contents:find("love%.") ~= nil
end

local function find_love_project_root(file_dir)
	local conf_paths = vim.fs.find("conf.lua", { path = file_dir, upward = true, type = "file" })
	if conf_paths[1] then
		return vim.fs.dirname(conf_paths[1])
	end

	local main_paths = vim.fs.find("main.lua", { path = file_dir, upward = true, type = "file" })
	for _, main_path in ipairs(main_paths) do
		local project_dir = vim.fs.dirname(main_path)
		if looks_like_love_project(project_dir) then
			return project_dir
		end
	end
	return nil
end

local function open_command_in_new_tab(command, cwd)
	local shell = vim.env.SHELL or vim.o.shell
	local shell_command = ("%s; exec %s -i"):format(command, vim.fn.shellescape(shell))

	vim.cmd("tabnew")
	vim.fn.termopen({ shell, "-ic", shell_command }, { cwd = cwd })
	vim.cmd("startinsert")
end

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

local function run_current_file_in_new_tab()
	local file_path = vim.fn.expand("%:p")

	if file_path == "" then
		vim.notify("Current buffer has no file path", vim.log.levels.WARN)
		return
	end

	local file_dir = vim.fn.fnamemodify(file_path, ":h")
	if vim.bo.filetype == "lua" then
		local love_project_root = find_love_project_root(file_dir)
		if love_project_root then
			local love_executable = find_available_executable({ "love" })
			if not love_executable then
				vim.notify("Could not find 'love' executable", vim.log.levels.ERROR)
				return
			end

			open_command_in_new_tab(("%s ."):format(vim.fn.shellescape(love_executable)), love_project_root)
			return
		end

		local lua_executable = find_available_executable({ "lua", "luajit" })
		if not lua_executable then
			vim.notify("Could not find 'lua' or 'luajit' executable", vim.log.levels.ERROR)
			return
		end

		open_command_in_new_tab(
			("%s %s"):format(vim.fn.shellescape(lua_executable), vim.fn.shellescape(file_path)),
			file_dir
		)
		return
	end

	local uv_executable = find_available_executable({ "uv" })
	if not uv_executable then
		vim.notify("Could not find 'uv' executable", vim.log.levels.ERROR)
		return
	end

	open_command_in_new_tab(("%s run %s"):format(vim.fn.shellescape(uv_executable), vim.fn.shellescape(file_path)), file_dir)
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

for i = 1, 9 do
	keymap("n", ("<leader>%d"):format(i), ("<cmd>tabnext %d<CR>"):format(i), {
		desc = ("Go to tab %d"):format(i),
	})
end

keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")
keymap("n", "<leader><leader>", "zz", { desc = "Center cursor line" })

keymap("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })
keymap("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all (force)" })
keymap("n", "<leader>e", show_line_diagnostics, { desc = "Show line diagnostics" })
keymap("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap("x", "<leader>rv", replace_in_selection, { desc = "Replace in selection" })

keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower split" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper split" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

keymap("n", "<leader>sv", "<cmd>vsplit<CR><cmd>Oil<CR>", { desc = "Vsplit and open Oil" })
keymap("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split horizontally" })
keymap("n", "<leader>s.", "<cmd>vsplit<CR><C-w>l<cmd>FzfLua files<CR>", { desc = "Vsplit and find files" })
keymap("n", "<leader>s,", "<cmd>vsplit<CR><C-w>l<cmd>FzfLua buffers<CR>", { desc = "Vsplit and switch buffer" })
keymap("n", "<leader>s/", "<cmd>vsplit<CR><C-w>l<cmd>FzfLua live_grep<CR>", { desc = "Vsplit and live grep" })
keymap("n", "<leader>s?", "<cmd>vsplit<CR><C-w>l<cmd>FzfLua help_tags<CR>", { desc = "Vsplit and help tags" })
keymap("n", "<leader>\\", "<cmd>vsplit<CR><cmd>terminal<CR>", { desc = "Vsplit and open terminal" })
keymap("n", "<leader>rr", run_current_file_in_new_tab, { desc = "Run file or Love project in new tab" })

keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })

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
