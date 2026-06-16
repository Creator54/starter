local is_scrollback = function()
  return vim.env.KITTY_SCROLLBACK_NVIM == "true"
end

return {
  {
    "folke/persistence.nvim",
    enabled = function() return not is_scrollback() end,
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
    init = function()
      -- Force options
      vim.opt.autowrite = true
      vim.opt.autowriteall = true
      vim.opt.sessionoptions = "curdir,buffers,tabpages,help,globals,folds,terminal"

      -- CLEAN STATE BEFORE ANY SESSION SAVE
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("SessionPreSave", { clear = true }),
        callback = function()
          if is_scrollback() then
            return
          end
          pcall(vim.cmd, "NvimTreeClose")
          pcall(vim.cmd, "%argdelete")
        end,
      })

      -- AUTO-RESTORE
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("NixAutoRestore", { clear = true }),
        callback = function()
          if is_scrollback() then
            return
          end
          local cwd = vim.fn.getcwd()
          if cwd == "" or cwd == "/" or cwd == "/tmp" then
            return
          end

          local argc = vim.fn.argc()
          local should_restore = (argc == 0) or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)

          if should_restore and not vim.g.started_with_stdin then
            -- Wipe any directory buffers from startup (netrw listings)
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) then
                local name = vim.api.nvim_buf_get_name(buf)
                if name ~= "" and vim.fn.isdirectory(name) == 1 then
                  pcall(vim.api.nvim_buf_delete, buf, { force = true })
                end
              end
            end

            -- Restore session if one exists
            local session_file = vim.fn.stdpath("state") .. "/sessions/"
              .. cwd:gsub("/", "%%") .. ".vim"
            if vim.fn.filereadable(session_file) == 1 then
              require("persistence").load()
            end

            -- Open Nvim-tree sidebar after everything settles
            vim.defer_fn(function()
              pcall(vim.cmd, "NvimTreeOpen")
            end, 300)
          end
        end,
        nested = true,
      })

      -- Clean up any extra empty/nameless or directory buffers after session restore
      local function cleanup_empty_buffers()
        vim.defer_fn(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
              local name = vim.api.nvim_buf_get_name(buf)
              local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
              local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
              local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

              -- Wipe nameless empty buffers
              local is_empty = name == "" and buftype == "" and not modified and #lines == 1 and lines[1] == ""
              -- Wipe directory buffers (netrw listings)
              local is_dir = name ~= "" and vim.fn.isdirectory(name) == 1

              if is_empty or is_dir then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
          end

          -- Restore focus to the last active file before quit
          local last_file = vim.g.SessionLastFile
          if last_file and last_file ~= "" and vim.fn.filereadable(last_file) == 1 then
            local target_buf = vim.fn.bufnr(last_file)
            if target_buf ~= -1 and vim.api.nvim_buf_is_valid(target_buf) then
              pcall(vim.api.nvim_set_current_buf, target_buf)
            end
          end

        end, 200)
      end

      vim.api.nvim_create_autocmd("SessionLoadPost", {
        group = vim.api.nvim_create_augroup("SessionCleanup", { clear = true }),
        callback = cleanup_empty_buffers,
        once = true,
      })
      vim.api.nvim_create_autocmd("User", {
        group = "SessionCleanup",
        pattern = "PersistenceLoadPost",
        callback = cleanup_empty_buffers,
        once = true,
      })
    end,
  },

  {
    "Pocco81/auto-save.nvim",
    enabled = function() return not is_scrollback() end,
    event = { "InsertLeave", "TextChanged" },
    opts = {
      debounce_delay = 135,
      execution_message = { message = "" },
    },
  },
}
