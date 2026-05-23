-- High-priority overrides for auto-save and session persistence

local is_scrollback = function()
  return vim.env.KITTY_SCROLLBACK_NVIM == "true"
end

return {
  -- 1. PERSISTENCE (Disable in scrollback mode)
  {
    "folke/persistence.nvim",
    enabled = function() return not is_scrollback() end,
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
  },

  -- 2. AUTO-SAVE (Disable in scrollback mode)
  {
    "Pocco81/auto-save.nvim",
    enabled = function() return not is_scrollback() end,
    event = { "InsertLeave", "TextChanged" },
    opts = {
      debounce_delay = 135,
      execution_message = { message = "" },
    },
  },

  -- 3. TOGGLETERM (Kill glitchy Alt+t)
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<A-t>", false },
    },
  },

  -- 4. NEO-TREE (Disable in scrollback mode)
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = function() return not is_scrollback() end,
    init = function()
      -- Delete LazyVim's auto-start augroup to prevent neo-tree from loading
      -- before VimEnter. This eliminates the race between neo-tree's 10ms
      -- debounced hijack and our session restore.
      pcall(vim.api.nvim_del_augroup_by_name, "Neotree_start_directory")
    end,
    opts = {
      window = {
        mappings = {
          ["<leader>Q"] = "none",
        }
      },
      source_selector = {
        winbar = false,
        statusline = false,
      },
      hide_root_node = true,
      retain_hidden_root_indent = true,
    },
  },

  -- 4. BUFFERLINE (Disable in scrollback mode)
  {
    "akinsho/bufferline.nvim",
    enabled = function() return not is_scrollback() end,
    opts = function(_, opts)
      opts.options = opts.options or {}
      -- Enable path context in tabs when filenames are ambiguous
      opts.options.show_buffer_close_icons = false
      opts.options.show_close_icon = false
      opts.options.separator_style = "thin"
      opts.options.diagnostics = "nvim_lsp"
      opts.options.offsets = opts.options.offsets or {}
      
      -- Kill "Neo-tree" sidebar title
      for _, offset in ipairs(opts.options.offsets) do
        if offset.filetype == "neo-tree" then
          offset.text = "" 
        end
      end

      -- Gruvbox-themed Highlights
      opts.highlights = {
        fill = { bg = "#1d2021" },
        background = { bg = "#282828", fg = "#928374" },
        buffer_selected = {
          bg = "#32302f",
          fg = "#8ec07c", -- Aqua for active file
          bold = true,
          italic = false,
        },
        buffer_visible = { bg = "#282828", fg = "#a89984" },
        separator = { fg = "#1d2021", bg = "#282828" },
        separator_selected = { fg = "#1d2021", bg = "#32302f" },
        modified_selected = { fg = "#d79921", bg = "#32302f" },
      }
      
      return opts
    end,
  },

  -- 5. LUALINE (Disable in scrollback mode)
  {
    "nvim-lualine/lualine.nvim",
    enabled = function() return not is_scrollback() end,
  },

  -- 6. BRUTE FORCE OVERRIDES
  {
    "LazyVim/LazyVim",
    init = function()
      -- Force options
      vim.opt.autowrite = true
      vim.opt.autowriteall = true
      vim.opt.sessionoptions = "curdir,buffers,tabpages,help,globals,folds,terminal"
      vim.opt.winbar = "" -- KEEP WINBAR DISABLED (avoid double header)

      -- STRIP UI IF IN SCROLLBACK MODE
      if is_scrollback() then
        vim.opt.laststatus = 0
        vim.opt.showtabline = 0
        vim.opt.number = false
        vim.opt.relativenumber = false
        vim.opt.signcolumn = "no"
        vim.opt.foldcolumn = "0"
        vim.opt.winbar = ""
        vim.g.lualine_enabled = false
      end

      -- FORCE DISABLE WINBAR on neo-tree (This kills the "Neo-tree" text)
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
        pattern = "neo-tree",
        callback = function()
          if is_scrollback() then
            return
          end
          vim.schedule(function()
            vim.opt_local.winbar = ""
            -- Force redraw
            vim.cmd("redrawstatus")
          end)
        end,
      })

      -- CLEAN STATE BEFORE ANY SESSION SAVE
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("SessionPreSave", { clear = true }),
        callback = function()
          if is_scrollback() then
            return
          end
          pcall(vim.cmd, "Neotree close")
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

            -- Open Neo-tree sidebar after everything settles
            vim.defer_fn(function()
              pcall(vim.cmd, "Neotree show")
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

      -- BULLETPROOF <leader>Q
      -- Register it multiple times to ensure we win
      local function apply_quit_fix()
        vim.keymap.set("n", "<leader>Q", function()
          -- 1. Store the active file path to preserve focus on restore
          vim.g.SessionLastFile = vim.fn.expand("%:p")

          -- 2. Close Neo-tree and clear arglist
          pcall(vim.cmd, "Neotree close")
          pcall(vim.cmd, "%argdelete")

          -- 3. Wipe directory buffers so they don't pollute the session file
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" and vim.fn.isdirectory(name) == 1 then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
          end

          -- 3. Save the perfect session state
          pcall(function() require("persistence").save() end)
          -- 4. Deactivate persistence auto-save to prevent qa! from overwriting it on exit
          pcall(function() require("persistence").stop() end)
          -- 5. Save all files to disk
          vim.cmd("silent! wa")
          -- 6. Quit Neovim safely and forcefully
          vim.cmd("qa!")
        end, { desc = "Save and Quit (Nix-Systems)", noremap = true, silent = true })
      end

      -- Run now
      apply_quit_fix()
      -- Run after a delay
      vim.defer_fn(apply_quit_fix, 500)
      -- Run when LazyVim is ready
      vim.api.nvim_create_autocmd("User", { pattern = "LazyVimStarted", callback = apply_quit_fix })
    end,
  },
}
