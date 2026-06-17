local function has_child_dir(parent, child)
	return vim.fn.isdirectory(vim.fs.joinpath(parent, child)) == 1
end

local function find_unity_project_root(start_path)
	local dir = start_path
	if vim.fn.filereadable(dir) == 1 then
		dir = vim.fs.dirname(dir)
	end

	while dir and dir ~= "" do
		if has_child_dir(dir, "Assets") and has_child_dir(dir, "ProjectSettings") then
			return dir
		end

		local parent = vim.fs.dirname(dir)
		if parent == dir then
			break
		end
		dir = parent
	end
end

local csharp_editorconfig = [[root = true

[*.cs]
indent_style = space
indent_size = 4
tab_width = 4
trim_trailing_whitespace = true
insert_final_newline = true

# Class/method vẫn kiểu C# truyền thống,
# if/else thì gọn:
# if (...) {
# } else {
csharp_new_line_before_open_brace = types, methods, properties, accessors, events, indexers
csharp_new_line_before_else = false
csharp_new_line_before_catch = false
csharp_new_line_before_finally = false

# using
dotnet_sort_system_directives_first = true
dotnet_separate_import_directive_groups = false
]]

vim.api.nvim_create_user_command("CsInit", function(opts)
	if opts.args ~= "" and opts.args ~= "init" then
		vim.notify("Usage: :CsInit or :cs init", vim.log.levels.ERROR)
		return
	end

	local current_file = vim.api.nvim_buf_get_name(0)
	local start_path = current_file ~= "" and current_file or vim.fn.getcwd()
	local root = find_unity_project_root(start_path) or vim.fn.getcwd()
	local editorconfig_path = vim.fs.joinpath(root, ".editorconfig")

	if vim.fn.filereadable(editorconfig_path) == 1 and not opts.bang then
		vim.notify(".editorconfig already exists: " .. editorconfig_path .. "\nUse :CsInit! to overwrite.", vim.log.levels.WARN)
		return
	end

	vim.fn.writefile(vim.split(csharp_editorconfig, "\n", { plain = true }), editorconfig_path)
	vim.notify("Created C# .editorconfig: " .. editorconfig_path, vim.log.levels.INFO)
end, {
	nargs = "*",
	bang = true,
	desc = "Create Unity/C# .editorconfig in project root",
})

vim.cmd([[cnoreabbrev <expr> cs getcmdtype() == ':' && getcmdline() ==# 'cs' ? 'CsInit' : 'cs']])
