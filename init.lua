vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

vim.api.nvim_create_autocmd("TermClose", {
  group = vim.api.nvim_create_augroup("DeleteLastLineTermClose", { clear = true }),
  pattern = { "*" },
  callback = function(ev)
    local delete_line_timer = vim.fn.timer_start(
      0,
      function(t) ---@diagnostic disable-line: redundant-parameter
        local process_exited_line = vim.fn.search("\\[process exited \\d\\]", "bn")
        if process_exited_line > 0 then
          vim.api.nvim_set_option_value("modifiable", true, { buf = ev.buf })
          vim.api.nvim_buf_set_lines(ev.buf, process_exited_line - 1, process_exited_line, true, { "" })
          vim.api.nvim_set_option_value("modifiable", false, { buf = ev.buf })
          vim.fn.timer_stop(t)
        end
      end,
      { ["repeat"] = -1 } -- repeat indefinitely but will be cancelled after 3 seconds
    )

    -- give at most 3 seconds of an attempt to delete the line
    vim.defer_fn(function()
      vim.fn.timer_stop(delete_line_timer)
    end, 100)
  end,
})

