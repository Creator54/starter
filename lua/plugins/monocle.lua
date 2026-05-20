local pi_term = nil

-- Helper to get Pi session directory format from path
local function get_session_dir()
  local cwd = vim.fn.getcwd()
  local session_dir = cwd:gsub("^/", ""):gsub("/$", ""):gsub("/", "-")
  return "--" .. session_dir .. "--"
end

-- Helper to check if a Pi session exists for the current directory
local function has_pi_session()
  local session_path = vim.fn.expand("~/.pi/agent/sessions/") .. get_session_dir()
  return vim.fn.isdirectory(session_path) == 1
end

return {
  {
    "akinsho/toggleterm.nvim",
    keys = {
      -- 1. PI AGENT (Resume/Toggle)
      {
        "<leader>ap",
        function()
          if not pi_term then
            local Terminal = require("toggleterm.terminal").Terminal
            pi_term = Terminal:new({
              cmd = "pi -r",
              dir = "git_dir",
              on_open = function(term)
                vim.cmd("startinsert!")
                vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<leader>ap", "<cmd>close<CR>", { noremap = true, silent = true })
              end,
            })
          end
          pi_term:toggle()
        end,
        desc = "Toggle Pi Agent (Resume)",
      },

      -- 3. PI AGENT (New Session)
      {
        "<leader>an",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local new_pi = Terminal:new({
            cmd = "pi",
            dir = "git_dir",
            close_on_exit = true,
            on_open = function(term)
              vim.cmd("startinsert!")
            end,
          })
          new_pi:toggle()
        end,
        desc = "New Pi Agent Session",
      },

      -- 4. PI SESSIONS (Selector Menu)
      {
        "<leader>as",
        function()
          local options = { "󰁯 Resume Current", "󰝒 New Session", "󰒲 List All" }
          vim.ui.select(options, { prompt = "Pi Agent Action" }, function(choice)
            if not choice then return end
            
            local cmd = "pi"
            if choice == "󰁯 Resume Current" or choice == "󰒲 List All" then
              cmd = "pi -r"
            end

            local Terminal = require("toggleterm.terminal").Terminal
            local term = Terminal:new({
              cmd = cmd,
              dir = "git_dir",
              close_on_exit = (choice == "󰒲 List All"),
              on_open = function(t)
                vim.cmd("startinsert!")
                -- If we resumed/started a main session, track it for <leader>ap
                if choice ~= "󰒲 List All" then
                  pi_term = t
                  vim.api.nvim_buf_set_keymap(t.bufnr, "t", "<leader>ap", "<cmd>close<CR>", { noremap = true, silent = true })
                end
              end,
            })
            term:toggle()
          end)
        end,
        desc = "Pi Agent Sessions Menu",
      },

      -- 5. PI CONTEXT (Visual Selection)
      {
        "<leader>ac",
        function()
          -- Get visual selection
          local _, srow, scol, _ = unpack(vim.fn.getpos("v"))
          local _, erow, ecol, _ = unpack(vim.fn.getpos("."))
          
          -- Handle reverse selection
          if srow > erow or (srow == erow and scol > ecol) then
            srow, erow = erow, srow
            scol, ecol = ecol, scol
          end

          local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
          if #lines == 0 then return end
          
          -- Adjust columns
          lines[#lines] = string.sub(lines[#lines], 1, ecol)
          lines[1] = string.sub(lines[1], scol)
          
          local selection = table.concat(lines, "\n")
          local filename = vim.fn.expand("%:.")

          -- Prompt for task
          vim.ui.input({ prompt = "Agent Task: " }, function(input)
            if not input or input == "" then return end

            -- Clean message for the chat history
            local message = string.format("Task: %s\n\nSnippet from '%s':\n```\n%s\n```", input, filename, selection)
            
            -- Background instruction for the agent (hidden from history)
            local system_append = string.format(
              "You are in 'Snippet Context Mode'. The user has provided a snippet from '%s'. " ..
              "You MUST answer based ONLY on this snippet. Do NOT use the 'read' tool or any other " ..
              "file-access tools to inspect the rest of the file or the project unless the user " ..
              "specifically asks you to explore. Treat the provided snippet as the ONLY code " ..
              "you have access to for this file.", 
              filename
            )

            -- Escape for shell
            local escaped_msg = message:gsub('"', '\\"'):gsub('`', '\\`'):gsub('%$', '\\$')
            local escaped_sys = system_append:gsub('"', '\\"'):gsub('`', '\\`'):gsub('%$', '\\$')
            
            local Terminal = require("toggleterm.terminal").Terminal
            local context_pi = Terminal:new({
              cmd = string.format('pi --append-system-prompt "%s" "%s"', escaped_sys, escaped_msg),
              dir = "git_dir",
              close_on_exit = false,
              on_open = function(term)
                vim.cmd("startinsert!")
                vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<leader>ac", "<cmd>close<CR>", { noremap = true, silent = true })
              end,
            })
            context_pi:toggle()
          end)
        end,
        mode = "v",
        desc = "Ask Pi with Selection",
      },
      
      -- 6. PI CONTEXT (Normal mode - current line)
      {
        "<leader>ac",
        function()
          local line = vim.api.nvim_get_current_line()
          local filename = vim.fn.expand("%:.")

          -- Prompt for task
          vim.ui.input({ prompt = "Agent Task (Line): " }, function(input)
            if not input or input == "" then return end

            local message = string.format("Task: %s\n\nLine from '%s':\n```\n%s\n```", input, filename, line)
            local system_append = string.format(
              "Prioritize the provided line from '%s'. Do NOT read the full file unless absolutely essential.", 
              filename
            )

            local escaped_msg = message:gsub('"', '\\"'):gsub('`', '\\`'):gsub('%$', '\\$')
            local escaped_sys = system_append:gsub('"', '\\"'):gsub('`', '\\`'):gsub('%$', '\\$')
            
            local Terminal = require("toggleterm.terminal").Terminal
            local context_pi = Terminal:new({
              cmd = string.format('pi --append-system-prompt "%s" "%s"', escaped_sys, escaped_msg),
              dir = "git_dir",
              close_on_exit = false,
              on_open = function(term)
                vim.cmd("startinsert!")
                vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<leader>ac", "<cmd>close<CR>", { noremap = true, silent = true })
              end,
            })
            context_pi:toggle()
          end)
        end,
        desc = "Ask Pi with Line",
      },
    },
  },
}
