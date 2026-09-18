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

local checktime_group = vim.api.nvim_create_augroup("user-checktime", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	group = checktime_group,
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.cmd("checktime")
		end
	end,
})
