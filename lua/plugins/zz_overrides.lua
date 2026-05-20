-- High-priority overrides for auto-save and session persistence

return {
  -- 1. PERSISTENCE
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
  },

  -- 2. AUTO-SAVE
  {
    "Pocco81/auto-save.nvim",
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

  -- 4. NEO-TREE (Cleaner UI)
  {
    "nvim-neo-tree/neo-tree.nvim",
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

  -- 4. BUFFERLINE (The actual file name header)
  {
    "akinsho/bufferline.nvim",
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

  -- 5. BRUTE FORCE OVERRIDES
  {
    "LazyVim/LazyVim",
    init = function()
      -- Force options
      vim.opt.autowrite = true
      vim.opt.autowriteall = true
      vim.opt.sessionoptions = "curdir,buffers,tabpages,winsize,help,globals,folds,terminal"
      vim.opt.winbar = "" -- KEEP WINBAR DISABLED (avoid double header)

      -- FORCE DISABLE WINBAR on neo-tree (This kills the "Neo-tree" text)
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
        pattern = "neo-tree",
        callback = function()
          vim.schedule(function()
            vim.opt_local.winbar = ""
            -- Force redraw
            vim.cmd("redrawstatus")
          end)
        end,
      })

      -- AUTO-RESTORE
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("NixAutoRestore", { clear = true }),
        callback = function()
          local cwd = vim.fn.getcwd()
          -- Don't restore if cwd is empty, root directory, or temp directory
          if cwd == "" or cwd == "/" or cwd == "/tmp" then
            return
          end

          -- Allow restore if:
          -- 1. No arguments are passed (nvim)
          -- 2. Exactly one directory argument is passed (nvim .)
          local argc = vim.fn.argc()
          local should_restore = (argc == 0) or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)

          if should_restore and not vim.g.started_with_stdin then
            require("persistence").load()
          end
        end,
        nested = true,
      })

      -- BULLETPROOF <leader>Q
      -- Register it multiple times to ensure we win
      local function apply_quit_fix()
        vim.keymap.set("n", "<leader>Q", function()
          -- Save everything
          pcall(function() require("persistence").save() end)
          vim.cmd("silent! wa")
          -- Final check: if we are still modified, something is wrong
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
