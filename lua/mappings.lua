require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Lazy updates
map("n", "<A-u>", "<cmd>:Lazy update<cr>", { desc = "Lazy update", silent = true })
map("n", "<A-S>", "<cmd>:Lazy sync<cr>", { desc = "Lazy sync", silent = true })

-- Bufferline / Tabufline cycle & close
map("n", "<A-`>", function() require("nvchad.tabufline").next() end, { desc = "Cycle forward through buffers", silent = true })
map("n", "<A-S-`>", function() require("nvchad.tabufline").prev() end, { desc = "Cycle backward through buffers", silent = true })
map("n", "<C-d>", function() require("nvchad.tabufline").close_buffer() end, { desc = "Close current buffer", silent = true })
map("n", "<S-l>", function() require("nvchad.tabufline").next() end, { desc = "Next buffer", silent = true })
map("n", "<S-h>", function() require("nvchad.tabufline").prev() end, { desc = "Previous buffer", silent = true })

-- Glow vertical split markdown viewer
map(
  "n",
  "<A-r>",
  ":vsplit<CR>:lua vim.cmd('term glow ' .. vim.fn.expand('%:p') .. ' -p')<CR>:setlocal nonumber norelativenumber<CR>i<CR>",
  { desc = "Open Glow with current file in split", silent = true }
)

-- Text and navigation helpers
map("n", "<C-a>", "gg<S-v>G", { desc = "Select all text", silent = true })
map("n", "gu", "<C-o>", { desc = "Go back in jumplist", silent = true })
map("n", "gU", "<C-i>", { desc = "Go forward in jumplist", silent = true })

-- Window resizing
map("n", "<A-Up>", ":resize +2<CR>", { desc = "Resize window up", silent = true })
map("n", "<A-Down>", ":resize -2<CR>", { desc = "Resize window down", silent = true })
map("n", "<A-Left>", ":vertical resize -2<CR>", { desc = "Resize window left", silent = true })
map("n", "<A-Right>", ":vertical resize +2<CR>", { desc = "Resize window right", silent = true })

-- Quick save & quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file", silent = true })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit buffer", silent = true })
map("n", "<leader><space>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights", silent = true })
map("n", "<F8>", "<cmd>set spell!<CR>", { desc = "Toggle spelling", silent = true })

-- Bulletproof Quit
map("n", "<leader>Q", function()
  -- 1. Store the active file path to preserve focus on restore
  vim.g.SessionLastFile = vim.fn.expand("%:p")

  -- 2. Close NvimTree sidebar and clear arglist to prevent session pollution
  pcall(vim.cmd, "NvimTreeClose")
  pcall(vim.cmd, "%argdelete")

  -- 3. Wipe out directory buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.fn.isdirectory(name) == 1 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end

  -- 4. Save persistence session state and stop
  pcall(function()
    require("persistence").save()
    require("persistence").stop()
  end)

  -- 5. Save all files to disk and exit
  vim.cmd("silent! wa")
  vim.cmd("qa!")
end, { desc = "Save and Quit (Nix-Systems)", silent = true })

-- Git Worktree open hub
map("n", "<A-t>", function()
  local ok, wt = pcall(require, "util.worktree")
  if ok then
    wt.open_hub()
  else
    vim.notify("Git worktree utility not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Git Worktree Hub", silent = true })

-- Toggle horizontal terminal (matching LazyVim style Ctrl+/ and Ctrl+_)
map({ "n", "t" }, "<C-/>", function()
  if _G.toggleterm_horizontal then
    _G.toggleterm_horizontal()
  else
    vim.notify("Toggleterm not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Toggle horizontal terminal", silent = true })

map({ "n", "t" }, "<C-_>", function()
  if _G.toggleterm_horizontal then
    _G.toggleterm_horizontal()
  else
    vim.notify("Toggleterm not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Toggle horizontal terminal", silent = true })

map({ "n", "t" }, "<C-\\>", function()
  if _G.toggleterm_floating then
    _G.toggleterm_floating()
  else
    vim.notify("Toggleterm not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Toggle floating terminal", silent = true })

-- Toggle NvimTree (matching LazyVim style Leader+e)
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle NvimTree", silent = true })

-- sshfs remote development mappings
map("n", "<leader>rc", "<cmd>SSHConnect<CR>", { desc = "Remote SSHFS: Connect", silent = true })
map("n", "<leader>rt", "<cmd>tabnew | SSHConnect<CR>", { desc = "Remote SSHFS: Connect in new tab", silent = true })
map("n", "<leader>rd", function()
  local ok, ws = pcall(require, "util.workspace")
  if ok then
    ws.switch_to_local()
  else
    vim.notify("Workspace utility not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Workspace: switch to local", silent = true })
map("n", "<leader>rl", function()
  local ok, ws = pcall(require, "util.workspace")
  if ok then
    ws.switch_to_local()
  else
    vim.notify("Workspace utility not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Workspace: switch to local", silent = true })

map("n", "<leader>rf", "<cmd>SSHFiles<CR>", { desc = "Remote SSHFS: Find files", silent = true })
map("n", "<leader>rg", "<cmd>SSHLiveGrep<CR>", { desc = "Remote SSHFS: Live grep", silent = true })

-- Workspace hub & pin
map("n", "<leader>rw", function()
  local ok, ws = pcall(require, "util.workspace")
  if ok then
    ws.open_hub()
  else
    vim.notify("Workspace utility not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Workspace: open hub", silent = true })

map("n", "<leader>rP", function()
  local ok, ws = pcall(require, "util.workspace")
  if ok then
    ws.pin_current_folder()
  else
    vim.notify("Workspace utility not loaded", vim.log.levels.ERROR)
  end
end, { desc = "Workspace: pin current folder", silent = true })

-- Tabpage navigation keymaps
map("n", "]t", "<cmd>tabnext<CR>", { desc = "Next tab page", silent = true })
map("n", "[t", "<cmd>tabprevious<CR>", { desc = "Previous tab page", silent = true })
map("n", "<leader>ta", "<cmd>tabnew<CR>", { desc = "New tab page", silent = true })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab page", silent = true })





