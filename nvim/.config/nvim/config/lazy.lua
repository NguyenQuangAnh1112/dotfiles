local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local config_path = vim.fn.stdpath("config")

if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

local plugin_specs = {
	"blink",
	"zenbones",
	-- "cole",
	-- "carvion",
	-- "vesper",
	-- "rose-pine",
	"flash",
	"fff",
	"format",
	"lsp",
	"mini",
	"oil",
	"progress",
	"render-markdown",
	"tabby",
	"tmux-navigator",
	"treesiter",
	"tpipeline",
}

local spec = vim.tbl_map(function(name)
	return dofile(("%s/plugins/%s.lua"):format(config_path, name))
end, plugin_specs)

require("lazy").setup({
	spec = spec,
	install = { colorscheme = { "zenbones" } },
	checker = { enabled = false },
})
