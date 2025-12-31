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
-- Go back to the previous location (equivalent to :e # or Ctrl-o)
vim.keymap.set("n", "gu", "<C-o>", opts("Go back to previous location"))
-- Go forward to the next location in jump list
vim.keymap.set("n", "gU", "<C-i>", opts("Go forward to next location"))

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts("Go to left window"))
vim.keymap.set("n", "<C-j>", "<C-w>j", opts("Go to lower window"))
vim.keymap.set("n", "<C-k>", "<C-w>k", opts("Go to upper window"))
vim.keymap.set("n", "<C-l>", "<C-w>l", opts("Go to right window"))

-- Resize windows with Alt+arrow keys (avoid conflicts with cursor/statusline)
vim.keymap.set("n", "<A-Up>", ":resize +2<CR>", opts("Resize window up"))
vim.keymap.set("n", "<A-Down>", ":resize -2<CR>", opts("Resize window down"))
vim.keymap.set("n", "<A-Left>", ":vertical resize -2<CR>", opts("Resize window left"))
vim.keymap.set("n", "<A-Right>", ":vertical resize +2<CR>", opts("Resize window right"))

-- Quick save and quit
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", opts("Save file"))
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", opts("Quit buffer"))
vim.keymap.set("n", "<leader>Q", "<cmd>qa<CR>", opts("Quit all"))

-- Buffer navigation
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", opts("Next buffer"))
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", opts("Previous buffer"))

-- Clear search highlighting
vim.keymap.set("n", "<leader><space>", "<cmd>nohlsearch<CR>", opts("Clear search highlights"))

-- Toggle spelling
vim.keymap.set("n", "<F8>", "<cmd>set spell!<CR>", opts("Toggle spelling"))
