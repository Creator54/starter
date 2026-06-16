local M = {}

-- Cache to avoid shelling out to git on every statusline redraw
local _cache = {
  in_git_repo = nil,
  last_cwd = nil,
}

-- Checks if a branch is a default branch (main or master, or current main worktree branch)
function M.is_default_branch(name)
  if name == "main" or name == "master" then
    return true
  end
  local default_branch = M.get_default_branch()
  return name == default_branch
end

-- Checks if the current directory is inside a git repository (cached per cwd)
function M.in_git_repo()
  local cwd = vim.fn.getcwd()
  if _cache.last_cwd == cwd and _cache.in_git_repo ~= nil then
    return _cache.in_git_repo
  end
  vim.fn.system("git rev-parse --is-inside-work-tree")
  _cache.in_git_repo = (vim.v.shell_error == 0)
  _cache.last_cwd = cwd
  return _cache.in_git_repo
end

-- Invalidate the git repo cache (call after switching worktrees)
function M.invalidate_cache()
  _cache.in_git_repo = nil
  _cache.last_cwd = nil
end

-- Helper to check if Nvim-tree sidebar is currently open in the active tab
local function check_neotree_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "NvimTree" then
        return true
      end
    end
  end
  return false
end

-----------------------------------------------------------------------
-- Unified Floating UI Custom Dialog Helpers (Ultra-Compact Version)
-----------------------------------------------------------------------

-- Centered floating text input box matching the hub's rounded style (height = 2)
function M.unified_input(title_text, callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 50
  local height = 2

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title_text .. " ",
    title_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "worktree_input"

  -- Disable autocomplete for standard Vim/Neovim, cmp, blink, coc, coq, etc.
  vim.opt_local.complete = ""
  vim.opt_local.completeopt = ""
  vim.bo[buf].omnifunc = ""
  vim.bo[buf].tagfunc = ""
  vim.bo[buf].completefunc = ""

  vim.b[buf].cmp_enabled = false
  vim.b[buf].coc_enabled = false
  vim.b[buf].completion = false
  vim.b[buf].completion_enabled = false
  vim.b[buf].coq_enabled = false

  pcall(function()
    require("cmp").setup.buffer({ enabled = false })
  end)
  pcall(function()
    require("blink.cmp").setup.buffer({ enabled = false })
  end)

  -- Pre-populate typing line with 2 spaces for perfect indentation
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "  ",
    "  Press <Enter> to Submit | <Esc> to Cancel",
  })
  vim.bo[buf].modifiable = true

  -- Highlights
  local ns = vim.api.nvim_create_namespace("git_worktree_input")
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 1, 0, -1)

  -- Position cursor on line 1, column 2 (end of pre-populated spaces)
  pcall(vim.api.nvim_win_set_cursor, win, { 1, 2 })
  vim.cmd("startinsert!")

  local closed = false
  local function close_win()
    if closed then
      return
    end
    closed = true
    vim.cmd("stopinsert")
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local map_opts = { buffer = buf, nowait = true, silent = true, noremap = true }

  -- Submit
  vim.keymap.set({ "n", "i" }, "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
    local val = lines[1] and lines[1]:gsub("^%s*", ""):gsub("%s*$", "") or ""
    close_win()
    if val ~= "" then
      callback(val)
    end
  end, map_opts)

  -- Cancel
  vim.keymap.set({ "n", "i" }, "<Esc>", close_win, map_opts)
  vim.keymap.set("n", "q", close_win, map_opts)
end

-- Centered floating confirmation dialog matching the hub's rounded style (height = 2)
function M.unified_confirm(title_text, callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = #title_text + 6
  if width < 38 then
    width = 38
  end
  local height = 2

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title_text .. " ",
    title_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "",
    "  [y] Yes      [n] No / Cancel",
  })
  vim.bo[buf].modifiable = false

  -- Highlights
  local ns = vim.api.nvim_create_namespace("git_worktree_confirm")
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 1, 0, -1)

  -- Position cursor on the 'y' choice (line 2, column 3)
  pcall(vim.api.nvim_win_set_cursor, win, { 2, 3 })

  local closed = false
  local function close_win()
    if closed then
      return
    end
    closed = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local map_opts = { buffer = buf, nowait = true, silent = true, noremap = true }

  -- Confirm options
  vim.keymap.set("n", "y", function()
    close_win()
    callback(true)
  end, map_opts)

  vim.keymap.set("n", "<CR>", function()
    close_win()
    callback(true)
  end, map_opts)

  vim.keymap.set("n", "n", function()
    close_win()
    callback(false)
  end, map_opts)

  vim.keymap.set("n", "<Esc>", close_win, map_opts)
  vim.keymap.set("n", "q", close_win, map_opts)
end

-----------------------------------------------------------------------
-- Core Worktree Logic
-----------------------------------------------------------------------

-- Retrieves the list of Git worktrees
function M.get_worktrees()
  if not M.in_git_repo() then
    return {}
  end

  local lines = vim.fn.systemlist("git worktree list --porcelain")
  local worktrees = {}
  local current_wt = nil
  local wt_count = 0

  for _, line in ipairs(lines) do
    if line:sub(1, 9) == "worktree " then
      if current_wt then
        table.insert(worktrees, current_wt)
      end
      wt_count = wt_count + 1
      current_wt = {
        path = line:sub(10),
        branch = nil,
        is_current = false,
        is_default = (wt_count == 1),
      }
    elseif line:sub(1, 7) == "branch " then
      local ref = line:sub(8)
      local branch = ref:match("refs/heads/(.*)")
      if branch and current_wt then
        current_wt.branch = branch
      end
    end
  end
  if current_wt then
    table.insert(worktrees, current_wt)
  end

  -- Detect current worktree
  local current_cwd = vim.fn.getcwd()
  local resolved_cwd = vim.fn.fnamemodify(current_cwd, ":p"):gsub("/$", "")

  for _, wt in ipairs(worktrees) do
    local resolved_wt = vim.fn.fnamemodify(wt.path, ":p"):gsub("/$", "")
    if resolved_wt == resolved_cwd then
      wt.is_current = true
    end
  end

  return worktrees
end

--- Safely switch to a worktree using persistence session management.
--- @param path string Target worktree path
--- @param opts_switch table|nil Options: { skip_neotree = bool, on_done = function }
function M.switch_worktree(path, opts_switch)
  opts_switch = opts_switch or {}
  local resolved_path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  local current_cwd = vim.fn.getcwd()
  local resolved_cwd = vim.fn.fnamemodify(current_cwd, ":p"):gsub("/$", "")

  if resolved_path == resolved_cwd then
    vim.notify("Already in the target worktree", vim.log.levels.INFO, { title = "Git Worktree" })
    if opts_switch.on_done then
      opts_switch.on_done()
    end
    return
  end

  -- Detect if Nvim-tree is open before shutting down the session
  local neotree_was_open = check_neotree_open()

  -- 1. Store active file path to preserve focus
  vim.g.SessionLastFile = vim.fn.expand("%:p")

  -- 2. Close Nvim-tree sidebar and clear arglist to prevent session pollution
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

  -- 4. Save current persistence session state
  pcall(function()
    require("persistence").save()
    require("persistence").stop()
  end)

  -- 5. Wipe out all buffers to prevent background files leaking into the new session
  vim.cmd("silent! %bd!")

  -- 6. Invalidate git cache and change directory
  M.invalidate_cache()
  vim.cmd("cd " .. vim.fn.fnameescape(resolved_path))

  -- 7. Load or start the session in the new directory
  local session_file = vim.fn.stdpath("state") .. "/sessions/" .. resolved_path:gsub("/", "%%") .. ".vim"

  if vim.fn.filereadable(session_file) == 1 then
    pcall(function()
      require("persistence").load()
    end)
  else
    vim.notify("Started fresh session in worktree: " .. resolved_path, vim.log.levels.INFO, { title = "Git Worktree" })
  end

  -- 8. Enable persistence back
  pcall(function()
    require("persistence").start()
  end)

  -- 9. Restore Nvim-tree sidebar if it was open previously (unless skipped)
  if not opts_switch.skip_neotree and neotree_was_open then
    vim.defer_fn(function()
      pcall(vim.cmd, "NvimTreeOpen")
    end, 300)
  end

  -- 10. Fire completion callback
  if opts_switch.on_done then
    vim.defer_fn(opts_switch.on_done, 350)
  end
end

-- Get default branch of the repository (normally main or master)
function M.get_default_branch()
  local worktrees = M.get_worktrees()
  for _, wt in ipairs(worktrees) do
    if wt.is_default and wt.branch then
      return wt.branch
    end
  end
  return "main" -- fallback
end

-- Get default branch worktree path
function M.get_default_worktree_path()
  local worktrees = M.get_worktrees()
  for _, wt in ipairs(worktrees) do
    if wt.is_default then
      return wt.path
    end
  end
  return nil
end

-- Prompts for a new worktree name using the beautiful centered float
function M.prompt_create()
  M.unified_input("New Git Worktree", function(input)
    M.create_worktree(input)
  end)
end

function M.create_worktree(name)
  if not name or name == "" then
    return
  end

  local default_path = M.get_default_worktree_path()
  if not default_path then
    vim.notify("Default worktree path not found", vim.log.levels.ERROR, { title = "Git Worktree" })
    return
  end

  local git_dir = default_path .. "/.git"
  local worktrees_dir
  if vim.fn.isdirectory(git_dir) == 1 then
    worktrees_dir = git_dir .. "/worktrees-checkouts"
  else
    worktrees_dir = default_path .. "/.worktrees"
  end
  vim.fn.mkdir(worktrees_dir, "p")

  -- Ensure fallback path is in local git exclude to keep git status clean locally
  if worktrees_dir == default_path .. "/.worktrees" then
    local exclude_file = default_path .. "/.git/info/exclude"
    local f = io.open(exclude_file, "r")
    local content = ""
    if f then
      content = f:read("*all")
      f:close()
    end
    if not content:find("%.worktrees/?") then
      f = io.open(exclude_file, "a")
      if f then
        f:write("\n# Local git worktrees\n.worktrees/\n")
        f:close()
      end
    end
  end

  local new_path = worktrees_dir .. "/" .. name

  if vim.fn.isdirectory(new_path) == 1 then
    vim.notify("Directory already exists at " .. new_path, vim.log.levels.ERROR, { title = "Git Worktree" })
    return
  end

  vim.notify("Creating worktree '" .. name .. "'...", vim.log.levels.INFO, { title = "Git Worktree" })

  local out =
    vim.fn.system(string.format("git worktree add %s -b %s", vim.fn.shellescape(new_path), vim.fn.shellescape(name)))
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to create worktree: " .. out, vim.log.levels.ERROR, { title = "Git Worktree" })
    return
  end

  M.switch_worktree(new_path)
end

-- Deletes a worktree (called after user confirms via hub)
function M.delete_worktree(wt)
  if M.is_default_branch(wt.branch) then
    vim.notify(
      "Cannot delete default branch '" .. wt.branch .. "'! (Delete Guard active)",
      vim.log.levels.ERROR,
      { title = "Git Worktree" }
    )
    return
  end

  M.unified_confirm("Delete '" .. wt.branch .. "' worktree?", function(confirmed)
    if not confirmed then
      vim.notify("Deletion cancelled", vim.log.levels.INFO, { title = "Git Worktree" })
      return
    end

    local function do_delete()
      -- Remove the worktree
      local out = vim.fn.system(string.format("git worktree remove %s", vim.fn.shellescape(wt.path)))
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed to remove worktree: " .. out, vim.log.levels.ERROR, { title = "Git Worktree" })
        return
      end

      -- Delete the branch
      local out_branch = vim.fn.system(string.format("git branch -D %s", vim.fn.shellescape(wt.branch)))
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed to delete branch: " .. out_branch, vim.log.levels.WARN, { title = "Git Worktree" })
      else
        vim.notify("Deleted worktree and branch '" .. wt.branch .. "'", vim.log.levels.INFO, { title = "Git Worktree" })
      end

      -- Kill associated tmux sessions
      local hash = vim.fn.sha256(wt.path):sub(1, 8)
      local sessions = vim.fn.systemlist("tmux list-sessions -F '#S' 2>/dev/null")
      if vim.v.shell_error == 0 then
        for _, session in ipairs(sessions) do
          if session:sub(-#hash - 1) == "_" .. hash then
            vim.fn.system("tmux kill-session -t " .. vim.fn.shellescape(session))
          end
        end
      end
    end

    if wt.is_current then
      local default_path = M.get_default_worktree_path()
      local default_branch = M.get_default_branch()
      if not default_path then
        vim.notify(
          "Cannot switch away: default branch worktree path not found",
          vim.log.levels.ERROR,
          { title = "Git Worktree" }
        )
        return
      end
      vim.notify("Switching to '" .. default_branch .. "'...", vim.log.levels.INFO, { title = "Git Worktree" })
      M.switch_worktree(default_path, { on_done = do_delete })
    else
      do_delete()
    end
  end)
end

-- Merges a worktree into the default branch via floating terminal
function M.merge_worktree(wt)
  if M.is_default_branch(wt.branch) then
    vim.notify("Cannot merge default branch '" .. wt.branch .. "'", vim.log.levels.ERROR, { title = "Git Worktree" })
    return
  end

  local default_path = M.get_default_worktree_path()
  local default_branch = M.get_default_branch()
  if not default_path or not default_branch then
    vim.notify("Default worktree/branch not found", vim.log.levels.ERROR, { title = "Git Worktree" })
    return
  end

  -- Capture whether Neo-tree is open before starting the merge process
  local neotree_was_open = check_neotree_open()

  M.unified_confirm("Merge '" .. wt.branch .. "' into '" .. default_branch .. "'?", function(confirmed)
    if not confirmed then
      vim.notify("Merge cancelled", vim.log.levels.INFO, { title = "Git Worktree" })
      return
    end

    local function spawn_merge_terminal()
      local bash_script = table.concat({
        "GREEN='\\033[0;32m'",
        "PURPLE='\\033[0;35m'",
        "RED='\\033[0;31m'",
        "NC='\\033[0m'",
        "",
        'echo -e "${PURPLE}=== Starting 5-Phase Git Merge Flow ===${NC}"',
        'echo ""',
        "",
        "# Phase 1: Sync",
        'echo -e "${PURPLE}[Phase 1/5] Syncing remote origin...${NC}"',
        "git fetch origin",
        "if [ $? -ne 0 ]; then",
        '    echo -e "${RED}✗ Fetch failed. Aborting.${NC}"',
        "    exit 1",
        "fi",
        'echo -e "${GREEN}✓ Remote synced successfully.${NC}"',
        'echo ""',
        "",
        "# Phase 2: Prepare",
        'echo -e "${PURPLE}[Phase 2/5] Preparing worktree...${NC}"',
        'if [ -d "' .. wt.path .. '" ]; then',
        '    cd "' .. wt.path .. '"',
        '    if [ ! -z "$(git status --porcelain)" ]; then',
        '        echo -e "${RED}✗ Worktree has uncommitted changes. Please commit or stash them first.${NC}"',
        "        exit 1",
        "    fi",
        "fi",
        'echo -e "${GREEN}✓ Worktree is clean.${NC}"',
        'echo ""',
        "",
        "# Phase 3: Squash",
        'echo -e "${PURPLE}[Phase 3/5] Squashing changes into ' .. default_branch .. '...${NC}"',
        'cd "' .. default_path .. '"',
        "if [ $? -ne 0 ]; then",
        '    echo -e "${RED}✗ Failed to access default worktree path: ' .. default_path .. '${NC}"',
        "    exit 1",
        "fi",
        'git merge --squash "' .. wt.branch .. '"',
        "if [ $? -ne 0 ]; then",
        '    echo -e "${RED}✗ Squash merge failed. Resolving conflicts may be required.${NC}"',
        "    exit 1",
        "fi",
        'echo -e "${GREEN}✓ Squash merge prepared.${NC}"',
        'echo ""',
        "",
        "# Phase 4: Commit",
        'echo -e "${PURPLE}[Phase 4/5] Committing squash...${NC}"',
        "if git diff --cached --quiet; then",
        '    echo -e "${GREEN}✓ No changes to commit (already up to date with ' .. default_branch .. ').${NC}"',
        "else",
        "    git commit -m \"Merge branch '" .. wt.branch .. "'\"",
        "    if [ $? -ne 0 ]; then",
        '        echo -e "${RED}✗ Commit failed.${NC}"',
        "        exit 1",
        "    fi",
        '    echo -e "${GREEN}✓ Squash merge committed.${NC}"',
        "fi",
        'echo ""',
        "",
        "# Phase 5: Cleanup",
        'echo -e "${PURPLE}[Phase 5/5] Cleaning up worktree and branch...${NC}"',
        'git worktree remove "' .. wt.path .. '"',
        'git branch -D "' .. wt.branch .. '"',
        'hash=$(echo -n "' .. wt.path .. '" | sha256sum | cut -c1-8)',
        'tmux list-sessions -F "#S" 2>/dev/null | grep "_$hash$" | while read -r s; do tmux kill-session -t "$s"; done',
        'echo -e "${GREEN}✓ Cleaned up feature worktree, branch, and active tmux sessions.${NC}"',
        'echo ""',
        'echo -e "${GREEN}=== Merge flow completed successfully! ===${NC}"',
      }, "\n")

      -- Write script to a temporary executable file to keep statusline completely clean
      local tmp_file = vim.fn.tempname() .. "_merge.sh"
      local f = io.open(tmp_file, "w")
      if f then
        f:write("#!/usr/bin/env bash\n" .. bash_script .. '\nrm -f "$0"\n')
        f:close()
        vim.fn.setfperm(tmp_file, "rwxr-xr-x")
      else
        vim.notify("Failed to write temporary merge script", vim.log.levels.ERROR, { title = "Git Worktree" })
        return
      end

      local Terminal = require("toggleterm.terminal").Terminal
      local merge_term = Terminal:new({
        cmd = tmp_file,
        close_on_exit = false,
        direction = "float",
        on_open = function(_)
          vim.cmd("startinsert!")
        end,
        on_close = function(_)
          if neotree_was_open then
            pcall(vim.cmd, "NvimTreeOpen")
          end
        end,
      })
      merge_term:toggle()
    end

    -- Switch to default worktree first (skip Neo-tree to avoid invalid window error)
    if wt.is_current then
      M.switch_worktree(default_path, {
        skip_neotree = true,
        on_done = spawn_merge_terminal,
      })
    else
      spawn_merge_terminal()
    end
  end)
end

-----------------------------------------------------------------------
-- Floating Worktree UI
-----------------------------------------------------------------------

function M.open_hub()
  if not M.in_git_repo() then
    vim.notify("Not inside a Git repository", vim.log.levels.ERROR, { title = "Git Worktree" })
    return
  end

  local worktrees = M.get_worktrees()
  if #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN, { title = "Git Worktree" })
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local width = 74
  local height = #worktrees + 4

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " 󰙅 Git Worktree",
    title_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  -- Render content
  local lines = {
    "  <CR> Switch  <a> Add  <d> Delete  <m> Merge  <q/Esc> Close",
    "  " .. string.rep("─", width - 4),
    "",
  }

  local wt_mapping = {}

  for _, wt in ipairs(worktrees) do
    local prefix = "    "
    local suffix = ""
    if wt.is_current and wt.is_default then
      prefix = "  ● "
      suffix = " (current · default)"
    elseif wt.is_current then
      prefix = "  ● "
      suffix = " (current)"
    elseif wt.is_default then
      prefix = "  󰇝 "
      suffix = " (default)"
    end

    local line_str = string.format("%s%s%s", prefix, wt.branch or "(no branch)", suffix)
    table.insert(lines, line_str)
    wt_mapping[#lines] = wt
  end

  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Highlights
  local ns = vim.api.nvim_create_namespace("git_worktree_hub")
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "FloatBorder", 1, 0, -1)

  for lnum, wt in pairs(wt_mapping) do
    local line_idx = lnum - 1
    if wt.is_current then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk", line_idx, 0, -1)
    elseif wt.is_default then
      vim.api.nvim_buf_add_highlight(buf, ns, "Keyword", line_idx, 0, -1)
    end
  end

  -- Position cursor on the current worktree line
  local first_wt_line = nil
  for lnum, wt in pairs(wt_mapping) do
    if not first_wt_line or lnum < first_wt_line then
      first_wt_line = lnum
    end
    if wt.is_current then
      pcall(vim.api.nvim_win_set_cursor, win, { lnum, 4 })
      first_wt_line = nil
      break
    end
  end
  if first_wt_line then
    pcall(vim.api.nvim_win_set_cursor, win, { first_wt_line, 4 })
  end

  -- Helpers
  local hub_closed = false
  local function close_win()
    if hub_closed then
      return
    end
    hub_closed = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function get_selected_wt()
    if not vim.api.nvim_win_is_valid(win) then
      return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    return wt_mapping[cursor[1]]
  end

  local map_opts = { buffer = buf, nowait = true, silent = true, noremap = true }

  -- CR: Switch to selected worktree
  vim.keymap.set("n", "<CR>", function()
    local wt = get_selected_wt()
    close_win()
    if wt then
      M.switch_worktree(wt.path)
    end
  end, map_opts)

  -- a: Add new worktree
  vim.keymap.set("n", "a", function()
    close_win()
    M.prompt_create()
  end, map_opts)

  -- d: Delete
  vim.keymap.set("n", "d", function()
    local wt = get_selected_wt()
    close_win()
    if wt then
      M.delete_worktree(wt)
    end
  end, map_opts)

  -- m: Merge
  vim.keymap.set("n", "m", function()
    local wt = get_selected_wt()
    close_win()
    if wt then
      M.merge_worktree(wt)
    end
  end, map_opts)

  -- Close keys
  vim.keymap.set("n", "q", close_win, map_opts)
  vim.keymap.set("n", "<Esc>", close_win, map_opts)
  vim.keymap.set("n", "<A-t>", close_win, map_opts)

  -- Safety: close if user navigates away
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = close_win,
  })
end

-----------------------------------------------------------------------
-- Keymap setup (called from plugins/worktree.lua)
-----------------------------------------------------------------------

function M.setup_keymaps()
  vim.keymap.set("n", "<A-t>", function()
    M.open_hub()
  end, { desc = "Git Worktree", noremap = true, silent = true })
end

return M
