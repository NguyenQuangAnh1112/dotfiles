vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.fcitx5")
require("config.lazy")

-- Load built-in packs after lazy.nvim so lazy doesn't strip them from runtimepath
pcall(vim.cmd.packadd, "cfilter")

