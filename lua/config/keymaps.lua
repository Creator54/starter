-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n","<A-u>","<cmd>:Lazy update<cr>", { desc = "Lazy update" })
vim.keymap.set("n","<A-S>","<cmd>:Lazy sync<cr>", { desc = "Lazy update" })
vim.keymap.set("n","<A-t>","<cmd>:terminal<cr>i", { desc = "Open terminal buffer" })
