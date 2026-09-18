local M = {}

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

function M.run()
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

return M
