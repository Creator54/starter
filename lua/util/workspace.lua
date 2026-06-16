local M = {}

-- --------------------------------------------------------------------------
--  Helpers
-- --------------------------------------------------------------------------

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

-- --------------------------------------------------------------------------
--  Pin storage helpers
-- --------------------------------------------------------------------------

local pin_file = vim.fn.stdpath("data") .. "/workspace_pins.json"

local function _load_pins()
  local ok, content = pcall(vim.fn.readfile, pin_file)
  if not ok or #content == 0 then
    return {}
  end
  local ok2, pins = pcall(vim.fn.json_decode, table.concat(content, "\n"))
  if not ok2 then
    return {}
  end
  return pins or {}
end

local function _save_pins(pins)
  local ok, json = pcall(vim.fn.json_encode, pins)
  if ok then
    pcall(vim.fn.writefile, { json }, pin_file)
  end
end

-- --------------------------------------------------------------------------
--  State capture (once per tab)
-- --------------------------------------------------------------------------

function M.save_current_state_once()
  if vim.t.workspace_local_cwd then
    return
  end

  vim.t.workspace_local_cwd = vim.fn.getcwd()
  vim.t.workspace_neotree_open = check_neotree_open()
  vim.g.SessionLastFile = vim.fn.expand("%:p")

  pcall(function()
    require("persistence").save()
    require("persistence").stop()
  end)
end

-- --------------------------------------------------------------------------
--  Cleanup before switching contexts
-- --------------------------------------------------------------------------

function M.cleanup_for_switch()
  pcall(vim.cmd, "NvimTreeClose")
  pcall(vim.cmd, "%argdelete")

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.fn.isdirectory(name) == 1 then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end

  vim.cmd("silent! %bd!")
end

-- --------------------------------------------------------------------------
--  Switch to remote workspace (SSH mount)
-- --------------------------------------------------------------------------

function M.switch_to_remote(mount_path, host_name, remote_path)
  -- Save current session before leaving
  pcall(function()
    require("persistence").save()
    require("persistence").stop()
  end)

  M.save_current_state_once()
  M.cleanup_for_switch()

  vim.cmd("tcd " .. vim.fn.fnameescape(mount_path))

  pcall(function()
    require("persistence").load()
    require("persistence").start()
  end)

  vim.t.workspace_is_remote = true
  vim.t.workspace_mount_path = mount_path
  vim.t.workspace_host_name = host_name
  vim.t.workspace_remote_path = remote_path

  vim.defer_fn(function()
    pcall(vim.cmd, "NvimTreeOpen")
  end, 100)
end

-- --------------------------------------------------------------------------
--  Switch back to local workspace
-- --------------------------------------------------------------------------

function M.switch_to_local()
  if not vim.t.workspace_is_remote then
    vim.notify("Already in local workspace", vim.log.levels.INFO)
    return
  end

  pcall(function()
    require("persistence").save()
    require("persistence").stop()
  end)

  M.cleanup_for_switch()

  local local_dir = vim.t.workspace_local_cwd or vim.fn.expand("~")
  vim.cmd("tcd " .. vim.fn.fnameescape(local_dir))

  pcall(function()
    require("persistence").load()
    require("persistence").start()
  end)

  vim.t.workspace_is_remote = false
  vim.t.workspace_mount_path = nil
  vim.t.workspace_host_name = nil
  vim.t.workspace_remote_path = nil

  vim.defer_fn(function()
    pcall(vim.cmd, "NvimTreeOpen")
  end, 100)
end

-- --------------------------------------------------------------------------
--  Floating hub UI
-- --------------------------------------------------------------------------

function M.open_hub()
  local ok_mp, MountPoint = pcall(require, "sshfs.lib.mount_point")
  if not ok_mp then
    vim.notify("sshfs.nvim not available", vim.log.levels.ERROR)
    return
  end

  local mounts = MountPoint.list_active() or {}
  local items = {}

  -- Local workspace entry
  local local_label = vim.t.workspace_is_remote and "  󰇝 Local" or "  ● Local"
  table.insert(items, { kind = "local", label = local_label, path = vim.t.workspace_local_cwd or vim.fn.getcwd() })

  -- Active SSH mounts
  for _, m in ipairs(mounts) do
    local label
    if vim.t.workspace_is_remote and vim.t.workspace_mount_path == m.mount_path then
      label = "  ● " .. (m.host or "unknown")
    else
      label = "  󰇝 " .. (m.host or "unknown")
    end
    table.insert(items, { kind = "remote", label = label, mount = m })
  end

  -- Add new connection option
  table.insert(items, { kind = "add", label = "  [a] Add new SSH connection" })

  local buf = vim.api.nvim_create_buf(false, true)
  local width = 60
  local height = #items + 3

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " 󰣀 Workspace Hub",
    title_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  local lines = {
    "  <CR> Switch  <a> Add  <q/Esc> Close",
    "  " .. string.rep("─", width - 4),
  }

  local item_mapping = {}

  for _, item in ipairs(items) do
    table.insert(lines, item.label)
    item_mapping[#lines] = item
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Highlights
  local ns = vim.api.nvim_create_namespace("workspace_hub")
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "FloatBorder", 1, 0, -1)

  for lnum, item in pairs(item_mapping) do
    local idx = lnum - 1
    if item.kind == "local" and not vim.t.workspace_is_remote then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk", idx, 0, -1)
    elseif item.kind == "remote" and vim.t.workspace_is_remote and vim.t.workspace_host_name == item.mount.host then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk", idx, 0, -1)
    end
  end

  -- Cursor position (first item)
  pcall(vim.api.nvim_win_set_cursor, win, { 3, 4 })

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

  local function get_selected_item()
    if not vim.api.nvim_win_is_valid(win) then
      return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    return item_mapping[cursor[1]]
  end

  local map_opts = { buffer = buf, nowait = true, silent = true, noremap = true }

  vim.keymap.set("n", "<CR>", function()
    local item = get_selected_item()
    close_win()
    if not item then
      return
    end
    if item.kind == "local" then
      M.switch_to_local()
    elseif item.kind == "remote" then
      M.switch_to_remote(item.mount.mount_path, item.mount.host, item.mount.remote_path)
    end
  end, map_opts)

  vim.keymap.set("n", "a", function()
    close_win()
    vim.cmd("SSHConnect")
  end, map_opts)

  vim.keymap.set("n", "q", close_win, map_opts)
  vim.keymap.set("n", "<Esc>", close_win, map_opts)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = close_win,
  })
end

-- --------------------------------------------------------------------------
--  Pin current folder scoped to mount_path
-- --------------------------------------------------------------------------

function M.pin_current_folder()
  if not vim.t.workspace_is_remote then
    vim.notify("Pin only works inside a remote workspace", vim.log.levels.WARN)
    return
  end

  local mount_path = vim.t.workspace_mount_path
  if not mount_path then
    vim.notify("No active mount found", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  if not cwd:find(vim.pesc(mount_path), 1, true) then
    vim.notify("Current directory is not under the mount path", vim.log.levels.WARN)
    return
  end

  local pins = _load_pins()
  pins[mount_path] = cwd
  _save_pins(pins)

  vim.notify("Pinned folder for " .. (vim.t.workspace_host_name or "remote") .. ": " .. cwd, vim.log.levels.INFO)
end

function M.get_pinned_folder(mount_path)
  local pins = _load_pins()
  return pins[mount_path]
end

function M.prompt_restore(mount_path, host_name)
  local pinned = M.get_pinned_folder(mount_path)
  if not pinned then
    return
  end

  vim.ui.select({ "Yes", "No" }, {
    prompt = "Restore pinned folder for " .. (host_name or "remote") .. "?\n" .. pinned,
  }, function(choice)
    if choice == "Yes" then
      vim.cmd("tcd " .. vim.fn.fnameescape(pinned))
      vim.defer_fn(function()
        pcall(vim.cmd, "NvimTreeOpen")
      end, 100)
      vim.notify("Restored pinned folder: " .. pinned, vim.log.levels.INFO)
    end
  end)
end

-- --------------------------------------------------------------------------
--  Keymap setup helper
-- --------------------------------------------------------------------------

function M.setup_keymaps()
  vim.keymap.set("n", "<leader>rl", function()
    M.switch_to_local()
  end, { desc = "Workspace: switch to local", noremap = true, silent = true })

  vim.keymap.set("n", "<leader>rw", function()
    M.open_hub()
  end, { desc = "Workspace: open hub", noremap = true, silent = true })

  vim.keymap.set("n", "<leader>rP", function()
    M.pin_current_folder()
  end, { desc = "Workspace: pin current folder", noremap = true, silent = true })
end

return M
