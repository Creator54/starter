-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.winblend = 0
vim.opt.pumblend = 0

-- Performance optimizations for large files and tmux compatibility
vim.g.loaded_matchparen = 1
vim.opt.cursorline = false
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.foldmethod = "manual"
vim.opt.foldenable = false
