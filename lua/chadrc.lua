-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

local is_scrollback = function()
  return vim.env.KITTY_SCROLLBACK_NVIM == "true"
end

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "onedark",
  transparency = true,
}

M.ui = {
  statusline = {
    enabled = not is_scrollback(),
    theme = "default",
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cwd", "cursor" },
    modules = {
      git = function()
        local stbufnr = function()
          return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
        end

        if not vim.b[stbufnr()].gitsigns_head or vim.b[stbufnr()].gitsigns_git_status then
          return ""
        end

        local git_status = vim.b[stbufnr()].gitsigns_status_dict

        local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
        local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
        local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
        
        -- Use the worktree branch icon
        local branch_name = "󰙅 " .. git_status.head

        return "%#St_gitIcons# " .. branch_name .. added .. changed .. removed
      end,
    },
  },


  tabufline = {
    enabled = not is_scrollback(),
  },
}

M.mason = {
  pkgs = {
    -- Lua
    "stylua",
    -- Python
    "black",
    "isort",
    "flake8",
    "debugpy",
    -- Go
    "gofumpt",
    "goimports",
    "golines",
    "golangci-lint",
    "delve",
    -- Web/JS/TS
    "prettier",
    "eslint_d",
    "js-debug-adapter",
    -- Shell
    "shfmt",
    "shellcheck",
  },
}

return M

