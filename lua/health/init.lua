-- lua/health/init.lua
-- Custom health check: run with :checkhealth nvim-config
--
-- Verifies external tool dependencies and maps them to the features that need them.

local M = {}

local function check_tool(name, feature, install_cmd, level)
  level = level or "error"
  local health = vim.health
  local ok = vim.fn.executable(name) == 1
  if ok then
    health.ok(string.format("`%s` found — enables %s", name, feature))
  else
    local msg = string.format("`%s` not found — %s will be unavailable", name, feature)
    if level == "warn" then
      health.warn(msg .. (install_cmd and ("\n  Install: `" .. install_cmd .. "`") or ""))
    else
      health.error(msg .. (install_cmd and ("\n  Install: `" .. install_cmd .. "`") or ""))
    end
  end
end

function M.check()
  local health = vim.health
  health.start "External Dependencies"

  -- Required
  check_tool("git", "git worktree management", "https://git-scm.com/downloads")
  check_tool("node", "Mason package manager (LSPs, formatters, linters)", "https://nodejs.org/")
  check_tool("npm", "Mason package installation", "https://docs.npmjs.com/downloading-and-installing-node-js-and-npm")

  -- Feature-gated
  check_tool("tmux", "per-tab tmux-backed terminals, worktree merge flow", "https://github.com/tmux/tmux/wiki/Installing", "warn")
  check_tool("ssh", "remote SSHFS workspace switching, remote terminals", "openssh package", "warn")
  check_tool("sshfs", "remote workspace mounting via sshfs.nvim", "sshfs package (e.g. `apt install sshfs`)", "warn")
  check_tool("glow", "markdown preview in split (`<A-r>`)", "https://github.com/charmbracelet/glow#installation", "warn")
  check_tool("pi", "Pi agent integration (`<leader>a*` keymaps)", "https://github.com/anthropics/pi", "warn")

  health.start "Neovim Runtime"

  local lazy_path = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
  if vim.fn.isdirectory(lazy_path) == 1 then
    health.ok "`lazy.nvim` plugin directory exists"
  else
    health.error "`lazy.nvim` not bootstrapped — restart Neovim to auto-install"
  end

  local base46_cache = vim.g.base46_cache
  if base46_cache and vim.fn.isdirectory(base46_cache) == 1 then
    health.ok "base46 theme cache directory exists"
  else
    health.warn "base46 cache not found — will be generated on next startup"
  end

  health.start "Optional Feature State"

  if vim.env.KITTY_SCROLLBACK_NVIM == "true" then
    health.info "Kitty scrollback mode is ACTIVE — UI chrome disabled by design"
  end

  if vim.env.DOTNET_SYSTEM_GLOBALIZATION_INVARIANT == "1" then
    health.info "`DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` is set (Marksman LSP NixOS workaround)"
  else
    health.info "Set `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` if running on NixOS (Marksman LSP)"
  end
end

return M
