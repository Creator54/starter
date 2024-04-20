-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local function opts(description)
  return {
    desc = description,
    noremap = true,
    silent = true,
  }
end

keymap.set("n", "<A-u>", "<cmd>:Lazy update<cr>", opts("Lazy update"))
keymap.set("n", "<A-S>", "<cmd>:Lazy sync<cr>", opts("Lazy update"))
keymap.set("n", "<A-t>", "<cmd>:terminal<cr>i", opts("Open terminal buffer"))
keymap.set("n", "<A-`>", "<cmd>:BufferLineCycleNext<cr>", opts("Cycle forwardthrough open buffers"))
keymap.set("n", "<A-S-`>", "<cmd>:BufferLineCyclePrev<cr>", opts("Cycle backword through open buffers"))
keymap.set("n", "<C-d>", ":bd<CR>", opts("Close current buffer"))

-- vim.keymap.set("n", "<A-r>", "<cmd>:Glow<cr>", { desc = "Open Glow with current file" })
vim.keymap.set(
  "n",
  "<A-r>",
  ":vsplit<CR>:lua vim.cmd('term glow ' .. vim.fn.expand('%:p') .. ' -p')<CR>:setlocal nonumber norelativenumber<CR>i<CR>",
  opts("Open Glow with current file in vertical split without line numbers")
)

vim.keymap.set("n", "<C-a>", "gg<S-v>G", opts("Select all text"))
