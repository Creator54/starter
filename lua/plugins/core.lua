return {
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  },
  {
    "creator54/onedark.nvim",
    config = function()
      require("onedark").setup({
        style = "darker",
        transparent = true,
      })
      require("onedark").load()
    end,
  },
  {
    "jackMort/ChatGPT.nvim",
    config = function()
      require("chatgpt").setup({
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
  { "ellisonleao/glow.nvim", config = true, cmd = "Glow" },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      -- Default setup
      require("toggleterm").setup({
        size = 15,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",  -- Default to float
        close_on_exit = false,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      -- Single terminal instance that we'll reconfigure
      local terminal = require("toggleterm.terminal").Terminal:new({
        direction = "float",
        size = 15,
        on_open = function(term)
          -- Set terminal keymaps
          local opts = { buffer = 0 }
          vim.keymap.set('t', '<C-\\><C-N>', [[<C-\><C-N>]], opts)
          vim.keymap.set('t', 'jk', [[<C-\><C-N>]], opts)
          vim.keymap.set('t', '<C-h>', [[<C-\><C-N><C-w>h]], opts)
          vim.keymap.set('t', '<C-j>', [[<C-\><C-N><C-w>j]], opts)
          vim.keymap.set('t', '<C-k>', [[<C-\><C-N><C-w>k]], opts)
          vim.keymap.set('t', '<C-l>', [[<C-\><C-N><C-w>l]], opts)
          vim.keymap.set('t', '<C-w>', [[<C-\><C-N><C-w>]], opts)
          -- Alt+h to switch to horizontal, Alt+t to toggle (close) the terminal
          vim.keymap.set('t', '<A-h>', [[<C-\><C-N>:lua _G.toggleterm_toggle_direction("horizontal")<CR>]], opts)
          vim.keymap.set('t', '<A-t>', [[<C-\><C-N>:ToggleTerm<CR>]], opts)
        end,
      })

      -- Set a timer to ensure insert mode when terminal is fully loaded
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "term://*toggleterm*",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
            vim.defer_fn(function()
              -- Only execute startinsert if the buffer is still valid and in terminal mode
              if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
                vim.cmd("startinsert")
              end
            end, 30)
          end
        end,
      })

      -- Function to toggle the terminal with current direction
      _G.toggleterm_toggle = function()
        terminal:toggle()
      end

      -- Function to change terminal direction and reopen if needed
      _G.toggleterm_toggle_direction = function(direction)
        local was_open = terminal:is_open()

        -- Close current terminal if open
        if was_open then
          terminal:close()
        end

        -- Update terminal direction
        terminal.direction = direction

        -- Update size based on direction
        if direction == "horizontal" then
          terminal.size = 20
        elseif direction == "float" then
          terminal.size = 15
        end

        -- Reopen if it was open before
        if was_open then
          vim.defer_fn(function()
            terminal:toggle()
          end, 10)
        else
          -- If it wasn't open, toggle it to open in new direction
          terminal:toggle()
        end
      end

      -- Specific toggle functions for each direction
      _G.toggleterm_floating = function()
        _G.toggleterm_toggle_direction("float")
      end

      _G.toggleterm_horizontal = function()
        _G.toggleterm_toggle_direction("horizontal")
      end
    end,
    keys = {
      { "<A-t>", ":lua _G.toggleterm_floating()<CR>", desc = "Toggle floating terminal" },
      { "<A-h>", ":lua _G.toggleterm_horizontal()<CR>", desc = "Toggle horizontal terminal" },
    },
  },
}
