local opt = vim.opt

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.g.pyindent_disable_parentheses_indenting = true

opt.number = true
opt.relativenumber = true
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.opt.clipboard = "unnamedplus"
	end,
})
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.cmdheight = 0
opt.laststatus = 0
opt.showtabline = (vim.env.TMUX and vim.env.TMUX ~= "") and 0 or 2

-- Native tabline (matching tmux style, replaces tabby.nvim)
local function setup_tabline_hl()
	vim.api.nvim_set_hl(0, "TabLineFill", { fg = "#9a9a9a", bg = "NONE" })
	vim.api.nvim_set_hl(0, "TabLine", { fg = "#9a9a9a", bg = "NONE" })
	vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffffff", bg = "NONE", bold = true })
end

setup_tabline_hl()

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("user-tabline-hl", { clear = true }),
	callback = setup_tabline_hl,
})

function _G.user_tabline()
	local s = ""
	for i = 1, vim.fn.tabpagenr("$") do
		local winnr = vim.fn.tabpagewinnr(i)
		local buflist = vim.fn.tabpagebuflist(i)
		local bufnr = buflist[winnr]
		local bufname = bufnr and vim.fn.bufname(bufnr) or ""

		local name
		if bufname == "" then
			name = "[No Name]"
		elseif bufname:match("^oil://") then
			name = vim.fn.fnamemodify(bufname:gsub("^oil://", ""):gsub("/+$", ""), ":t")
			if name == "" then
				name = "oil"
			end
		else
			name = vim.fn.fnamemodify(bufname, ":t:r")
			if name == "" then
				name = vim.fn.fnamemodify(bufname, ":t")
			end
		end

		local is_modified = false
		for _, b in ipairs(buflist) do
			if vim.api.nvim_buf_is_valid(b) and vim.bo[b].modified then
				is_modified = true
				break
			end
		end
		local mod = is_modified and "+" or ""

		local hl = (i == vim.fn.tabpagenr()) and "%#TabLineSel#" or "%#TabLine#"
		s = s .. hl .. " " .. i .. ":" .. name .. mod .. " "
	end
	return s .. "%#TabLineFill#"
end

opt.tabline = "%!v:lua.user_tabline()"
opt.splitright = true
opt.splitbelow = true
opt.cursorline = true
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.modeline = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.undofile = true

-- QoL options
opt.confirm = true
opt.nrformats:append({ "alpha" })
opt.wildoptions:append({ "fuzzy" })
opt.exrc = true

opt.foldmethod = "indent"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.fillchars:append({ fold = " " })

local checktime_group = vim.api.nvim_create_augroup("user-checktime", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	group = checktime_group,
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.cmd("checktime")
		end
	end,
})

local yank_group = vim.api.nvim_create_augroup("user-yank-highlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	group = yank_group,
	desc = "Highlight text on yank",
	callback = function()
		vim.hl.on_yank({ higroup = "Visual", timeout = 150 })
	end,
})

local markdown_group = vim.api.nvim_create_augroup("user-markdown-options", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = markdown_group,
	pattern = "markdown",
	callback = function()
		vim.opt_local.cursorline = false
	end,
})

