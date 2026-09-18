local opt = vim.opt

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.g.pyindent_disable_parentheses_indenting = true

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.opt.clipboard = "unnamedplus"
	end,
})
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.autoread = true
opt.updatetime = 250
opt.cmdheight = 0
opt.laststatus = 0
opt.showtabline = (vim.env.TMUX and vim.env.TMUX ~= "") and 0 or 2
opt.splitright = true
opt.splitbelow = true
opt.cursorline = true
-- opt.scrolloff = 8
-- opt.sidescrolloff = 8
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakindentopt = ""
opt.list = false
opt.showbreak = ""
opt.modeline = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.undofile = true

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.fillchars:append({ fold = " " })

function _G.custom_foldtext()
	local start_lnum = vim.v.foldstart
	local bufnr = vim.api.nvim_get_current_buf()
	local line = vim.fn.getline(start_lnum)

	local trimmed = line:gsub("%s*{?%s*$", "")
	local line_len = #trimmed

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return {
			{ trimmed, "Folded" },
			{ " ...", "Comment" },
		}
	end

	local tree = parser:parse()[1]
	if not tree then
		return {
			{ trimmed, "Folded" },
			{ " ...", "Comment" },
		}
	end

	local lang = parser:lang()
	local query = vim.treesitter.query.get(lang, "highlights")
	if not query then
		return {
			{ trimmed, "Folded" },
			{ " ...", "Comment" },
		}
	end

	local row = start_lnum - 1
	local captures_by_range = {}
	for id, node, _ in query:iter_captures(tree:root(), bufnr, row, row + 1) do
		local sr, sc, _, ec = node:range()
		if sr == row and sc < line_len then
			table.insert(captures_by_range, {
				start_col = sc,
				end_col = math.min(ec, line_len),
				hl = "@" .. query.captures[id],
			})
		end
	end

	table.sort(captures_by_range, function(a, b)
		if a.start_col == b.start_col then
			return a.end_col > b.end_col
		end
		return a.start_col < b.start_col
	end)

	local chunks = {}
	local curr_col = 0

	for _, cap in ipairs(captures_by_range) do
		if cap.start_col > curr_col then
			table.insert(chunks, { trimmed:sub(curr_col + 1, cap.start_col), "Normal" })
			curr_col = cap.start_col
		end
		if cap.end_col > curr_col then
			table.insert(chunks, { trimmed:sub(curr_col + 1, cap.end_col), cap.hl })
			curr_col = cap.end_col
		end
	end

	if curr_col < line_len then
		table.insert(chunks, { trimmed:sub(curr_col + 1, line_len), "Normal" })
	end

	table.insert(chunks, { " ...", "Comment" })

	-- Pad to fill the entire line so the Folded background extends edge-to-edge
	local win = vim.api.nvim_get_current_win()
	local wininfo = vim.fn.getwininfo(win)[1]
	local gutter = wininfo and wininfo.textoff or 0
	local max_width = vim.api.nvim_win_get_width(win) - gutter
	local total = 0
	for _, chunk in ipairs(chunks) do
		total = total + vim.fn.strdisplaywidth(chunk[1])
	end
	local padding = max_width - total
	if padding > 0 then
		table.insert(chunks, { string.rep(" ", padding), "Folded" })
	end

	return chunks
end

opt.foldtext = "v:lua.custom_foldtext()"

local function setup_fold_hl()
	local ok, cl = pcall(vim.api.nvim_get_hl, 0, { name = "CursorLine", link = false })
	local cl_bg = ok and cl and cl.bg or nil
	vim.api.nvim_set_hl(0, "Folded", { bg = cl_bg, bold = false })
end

setup_fold_hl()

local fold_hl_group = vim.api.nvim_create_augroup("user-fold-hl", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	group = fold_hl_group,
	callback = setup_fold_hl,
})

local checktime_group = vim.api.nvim_create_augroup("user-checktime", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	group = checktime_group,
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.cmd("checktime")
		end
	end,
})
