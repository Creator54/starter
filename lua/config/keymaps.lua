-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<A-u>", "<cmd>:Lazy update<cr>", { desc = "Lazy update" })
vim.keymap.set("n", "<A-S>", "<cmd>:Lazy sync<cr>", { desc = "Lazy update" })
vim.keymap.set("n", "<A-t>", "<cmd>:terminal<cr>i", { desc = "Open terminal buffer" })
vim.keymap.set("n", "<A-`>", "<cmd>:BufferLineCycleNext<cr>", { desc = "Cycle forwardthrough open buffers" })
vim.keymap.set("n", "<A-S-`>", "<cmd>:BufferLineCyclePrev<cr>", { desc = "Cycle backword through open buffers" })
vim.keymap.set("n", "<C-d>", ":bd<CR>", { desc = "Close current buffer", noremap = true, silent = true })

-- vim.keymap.set("n", "<A-r>", "<cmd>:Glow<cr>", { desc = "Open Glow with current file" })
vim.keymap.set(
  "n",
  "<A-r>",
  ":vsplit<CR>:lua vim.cmd('term glow ' .. vim.fn.expand('%:p') .. ' -p')<CR>:setlocal nonumber norelativenumber<CR>i<CR>",
  { desc = "Open Glow with current file in vertical split without line numbers", silent = true }
)

-- select all text
vim.keymap.set("n", "<C-a>", "gg<S-v>G", { desc = "Select all text" })
