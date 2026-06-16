return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      -- Default setup
      require("toggleterm").setup({
        size = 15,
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float", -- Default to float
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

      -- Specific toggle functions delegating to tmux_term
      _G.toggleterm_floating = function()
        require("util.tmux_term").toggle_float()
      end

      _G.toggleterm_horizontal = function()
        require("util.tmux_term").toggle_horizontal()
      end
    end,
    keys = {
      -- Disabling <A-t> for opening terminal since it's mapped to Git Worktree Hub
      { "<A-t>", false },
      { "<A-h>", ":lua _G.toggleterm_horizontal()<CR>", desc = "Toggle horizontal terminal" },
      { "<C-\\>", ":lua _G.toggleterm_floating()<CR>", desc = "Toggle floating terminal" },
      { "<C-/>", ":lua _G.toggleterm_horizontal()<CR>", desc = "Toggle horizontal terminal" },
      { "<C-_>", ":lua _G.toggleterm_horizontal()<CR>", desc = "Toggle horizontal terminal" },
    },
  },
}
