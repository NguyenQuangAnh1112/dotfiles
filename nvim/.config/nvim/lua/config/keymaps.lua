local keymap = vim.keymap.set

local diagnostics_float_win

local godot_filetypes = {
	gdresource = true,
	gdscript = true,
	gdshader = true,
}

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

local function find_godot_project_root(file_dir)
	local project_paths = vim.fs.find("project.godot", { path = file_dir, upward = true, type = "file" })
	if project_paths[1] then
		return vim.fs.dirname(project_paths[1])
	end
end

local runner_tabpage
local runner_job_id

local function open_command_in_new_tab(command, cwd)
	vim.cmd("silent! wall")

	if runner_tabpage and vim.api.nvim_tabpage_is_valid(runner_tabpage) then
		if runner_job_id then
			pcall(vim.fn.jobstop, runner_job_id)
		end
		local tab_nr = vim.api.nvim_tabpage_get_number(runner_tabpage)
		pcall(vim.cmd, tab_nr .. "tabclose!")
	end

	local shell = vim.env.SHELL or vim.o.shell
	local shell_command = ("%s; exec %s -i"):format(command, vim.fn.shellescape(shell))

	vim.cmd("tabnew")
	runner_tabpage = vim.api.nvim_get_current_tabpage()
	runner_job_id = vim.fn.termopen({ shell, "-ic", shell_command }, { cwd = cwd })
	vim.cmd("startinsert")
end

local function find_cmake_project_root(file_dir)
	local matches = vim.fs.find("CMakeLists.txt", { path = file_dir, upward = true, limit = math.huge, type = "file" })
	if #matches == 0 then
		return nil, nil
	end
	for i = #matches, 1, -1 do
		local f = io.open(matches[i], "r")
		if f then
			local content = f:read("*a")
			f:close()
			if content:match("project%s*%(") then
				return vim.fs.dirname(matches[i]), matches[i]
			end
		end
	end
	return vim.fs.dirname(matches[1]), matches[1]
end

local function get_cmake_targets(cmakelists_path)
	local f = io.open(cmakelists_path, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()

	local project_name = content:match("project%s*%([%s\n]*([%w_%-]+)")
	content = content:gsub("#[^\n]*", "")

	local targets = {}
	for target in content:gmatch("add_executable%s*%([%s\n]*([%w_%-${}]+)") do
		if target == "${PROJECT_NAME}" and project_name then
			table.insert(targets, project_name)
		elseif not target:find("%$") then
			table.insert(targets, target)
		end
	end
	return targets
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
	if godot_filetypes[vim.bo.filetype] then
		local godot_project_root = find_godot_project_root(file_dir)
		if not godot_project_root then
			vim.notify("Could not find project.godot", vim.log.levels.ERROR)
			return
		end

		local godot_executable = find_available_executable({ "godot", "godot4" })
		if not godot_executable then
			vim.notify("Could not find 'godot' or 'godot4' executable", vim.log.levels.ERROR)
			return
		end

		open_command_in_new_tab(
			("%s --path %s"):format(vim.fn.shellescape(godot_executable), vim.fn.shellescape(godot_project_root)),
			godot_project_root
		)
		return
	end

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

	if vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
		local cmake_root, cmakelists = find_cmake_project_root(file_dir)

		if cmake_root and cmakelists then
			local cmake_bin = find_available_executable({ "cmake" })
			if not cmake_bin then
				vim.notify("Could not find 'cmake' executable", vim.log.levels.ERROR)
				return
			end

			local targets = get_cmake_targets(cmakelists)
			if #targets == 0 then
				local build_files = vim.fn.globpath(cmake_root .. "/build", "*", false, true)
				for _, f in ipairs(build_files) do
					if vim.fn.executable(f) == 1 and vim.fn.isdirectory(f) == 0 then
						table.insert(targets, vim.fs.basename(f))
					end
				end
			end

			local ninja_bin = find_available_executable({ "ninja" })
			local gen_flag = ninja_bin and "-G Ninja" or ""

			local function run_target(target)
				local cmd = ("([ -f build/CMakeCache.txt ] || %s -B build %s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON) && "
					.. "%s --build build --parallel --target %s && "
					.. "([ -e compile_commands.json ] || [ ! -f build/compile_commands.json ] || ln -sf build/compile_commands.json .) && "
					.. "( [ -f ./build/bin/%s ] && ./build/bin/%s || ./build/%s )"):format(
					vim.fn.shellescape(cmake_bin),
					gen_flag,
					vim.fn.shellescape(cmake_bin),
					vim.fn.shellescape(target),
					vim.fn.shellescape(target),
					vim.fn.shellescape(target),
					vim.fn.shellescape(target)
				)
				open_command_in_new_tab(cmd, cmake_root)
			end

			if #targets == 1 then
				run_target(targets[1])
			elseif #targets > 1 then
				local stem = vim.fn.fnamemodify(file_path, ":t:r")
				if vim.tbl_contains(targets, stem) then
					run_target(stem)
				else
					vim.ui.select(targets, { prompt = "Select CMake target to run:" }, function(choice)
						if choice then
							run_target(choice)
						end
					end)
				end
			else
				local cmd = ("([ -f build/CMakeCache.txt ] || %s -B build %s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON) && "
					.. "%s --build build --parallel"):format(
					vim.fn.shellescape(cmake_bin),
					gen_flag,
					vim.fn.shellescape(cmake_bin)
				)
				open_command_in_new_tab(cmd, cmake_root)
			end
			return
		end

		local ext = vim.fn.fnamemodify(file_path, ":e")
		if ext == "h" or ext == "hpp" then
			vim.notify("Cannot run a standalone header file directly", vim.log.levels.WARN)
			return
		end

		local file_stem = vim.fn.fnamemodify(file_path, ":t:r")
		local out_bin = "./" .. file_stem
		local compiler = vim.bo.filetype == "cpp" and find_available_executable({ "g++", "clang++" })
			or find_available_executable({ "gcc", "clang" })

		if not compiler then
			vim.notify("No C/C++ compiler found", vim.log.levels.ERROR)
			return
		end

		local flags = vim.bo.filetype == "cpp" and "-std=c++23 -Wall -Wextra" or "-Wall -Wextra"
		local cmd = ("%s %s %s -o %s && %s"):format(
			vim.fn.shellescape(compiler),
			flags,
			vim.fn.shellescape(file_path),
			vim.fn.shellescape(out_bin),
			vim.fn.shellescape(out_bin)
		)
		open_command_in_new_tab(cmd, file_dir)
		return
	end

	if vim.bo.filetype == "python" then
		local uv_executable = find_available_executable({ "uv" })
		if not uv_executable then
			vim.notify("Could not find 'uv' executable", vim.log.levels.ERROR)
			return
		end

		open_command_in_new_tab(
			("%s run %s"):format(vim.fn.shellescape(uv_executable), vim.fn.shellescape(file_path)),
			file_dir
		)
		return
	end

	vim.notify("No runner configured for filetype: " .. (vim.bo.filetype ~= "" and vim.bo.filetype or "unknown"), vim.log.levels.WARN)
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
keymap("n", "<C-e>", "<C-e>j", { desc = "Scroll down and move cursor down" })
keymap("n", "<C-y>", "<C-y>k", { desc = "Scroll up and move cursor up" })

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
keymap("n", "<leader>\\", "<cmd>vsplit<CR><cmd>terminal<CR>", { desc = "Vsplit and open terminal" })
keymap("n", "<leader>rr", run_current_file_in_new_tab, { desc = "Run file or Love project in new tab" })

keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })

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

keymap("n", "z<Space>", close_all_methods, { desc = "Close all methods (keep class open)" })

local function smart_toggle_fold()
	if vim.fn.foldclosed(".") ~= -1 then
		pcall(vim.cmd, "normal! zO")
	else
		pcall(vim.cmd, "normal! zc")
	end
end

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
