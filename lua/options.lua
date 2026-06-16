require "nvchad.options"

local is_scrollback = function()
  return vim.env.KITTY_SCROLLBACK_NVIM == "true"
end

if is_scrollback() then
  vim.opt.laststatus = 0
  vim.opt.showtabline = 0
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = "no"
  vim.opt.foldcolumn = "0"
  vim.opt.winbar = ""
else
  vim.opt.winblend = 0
  vim.opt.pumblend = 0
  vim.g.loaded_matchparen = 1
  vim.opt.cursorline = false
  vim.opt.relativenumber = true
  vim.opt.number = true
  vim.opt.foldmethod = "manual"
  vim.opt.foldenable = false
end


