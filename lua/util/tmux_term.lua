-- tmux_term.lua — per-tab tmux-backed toggleterm terminals
local M = {}

-- --------------------------------------------------------------------------
--  Persistent registry: survives nvim restarts so tmux sessions can be
--  reattached with the same names
-- --------------------------------------------------------------------------
local _registry_file = vim.fn.stdpath("data") .. "/tmux_term_registry.json"

local function _load_registry()
  local ok, content = pcall(vim.fn.readfile, _registry_file)
  if not ok or #content == 0 then
    return { counter = 0, tabs = {} }
  end
  local ok2, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
  if not ok2 then
    return { counter = 0, tabs = {} }
  end
  return data or { counter = 0, tabs = {} }
end

local function _save_registry(data)
  local ok, json = pcall(vim.fn.json_encode, data)
  if ok then
    pcall(vim.fn.writefile, { json }, _registry_file)
  end
end

-- --------------------------------------------------------------------------
--  In-memory registry: tab_id -> host -> direction -> Terminal
-- --------------------------------------------------------------------------
local _registry = {}

local function get_tab_id()
  if vim.t.tmux_tab_id then
    return vim.t.tmux_tab_id
  end

  local reg = _load_registry()
  local cwd = vim.fn.getcwd()

  -- Try to reuse a tab entry with the same cwd
  for id_str, info in pairs(reg.tabs) do
    if info.cwd == cwd then
      vim.t.tmux_tab_id = tonumber(id_str)
      return vim.t.tmux_tab_id
    end
  end

  -- No match — mint a new id and persist
  reg.counter = reg.counter + 1
  vim.t.tmux_tab_id = reg.counter
  reg.tabs[tostring(vim.t.tmux_tab_id)] = { cwd = cwd }
  _save_registry(reg)

  return vim.t.tmux_tab_id
end

local function session_name(tab_id, direction)
  return string.format("nvim_tab%d_%s", tab_id, direction)
end

-- --------------------------------------------------------------------------
--  Workspace detection (SSHFS / Local)
-- --------------------------------------------------------------------------
local function get_workspace_info()
  local info = {
    is_remote = false,
    host = "local",
    cwd = vim.fn.getcwd(),
  }

  if vim.t.workspace_is_remote then
    info.is_remote = true
    info.host = vim.t.workspace_host_name or "remote"
    info.mount_path = vim.t.workspace_mount_path
    info.remote_path = vim.t.workspace_remote_path or "~"
  else
    local ok_mp, MountPoint = pcall(require, "sshfs.lib.mount_point")
    if ok_mp then
      local active_mounts = MountPoint.list_active() or {}
      local cwd = vim.fn.getcwd()
      for _, m in ipairs(active_mounts) do
        if cwd:sub(1, #m.mount_path) == m.mount_path then
          info.is_remote = true
          info.host = m.host or "remote"
          info.mount_path = m.mount_path
          info.remote_path = m.remote_path or "~"
          break
        end
      end
    end
  end

  if info.is_remote and info.mount_path then
    local local_cwd = vim.fn.getcwd()
    local rel = local_cwd:sub(#info.mount_path + 1)
    if rel:sub(1, 1) == "/" then
      rel = rel:sub(2)
    end

    local remote_base = info.remote_path
    if remote_base == "~" then
      remote_base = "$HOME"
    elseif remote_base:sub(1, 2) == "~/" then
      remote_base = "$HOME" .. remote_base:sub(2)
    end

    if rel == "" then
      info.remote_cwd = remote_base
    else
      info.remote_cwd = remote_base .. "/" .. rel
    end
  end

  return info
end

-- --------------------------------------------------------------------------
--  Terminal keymaps
-- --------------------------------------------------------------------------
local function make_on_open(direction)
  return function(term)
    local bufnr = term.bufnr
    local display_name = term.display_name or "Terminal"
    local tab_id = get_tab_id()
    local new_name = string.format("term:///ToggleTerm/%d/%s;#toggleterm#%d", tab_id, display_name, term.id)
    pcall(vim.api.nvim_buf_set_name, bufnr, new_name)

    local opts = { buffer = bufnr }
    vim.keymap.set("t", "<C-\\><C-N>", [[<C-\><C-N>]], opts)
    vim.keymap.set("t", "jk", [[<C-\><C-N>]], opts)
    vim.keymap.set("t", "<C-h>", [[<C-\><C-N><C-w>h]], opts)
    vim.keymap.set("t", "<C-j>", [[<C-\><C-N><C-w>j]], opts)
    vim.keymap.set("t", "<C-k>", [[<C-\><C-N><C-w>k]], opts)
    vim.keymap.set("t", "<C-l>", [[<C-\><C-N><C-w>l]], opts)
    vim.keymap.set("t", "<C-w>", [[<C-\><C-N><C-w>]], opts)
    vim.keymap.set("t", "<A-h>", [[<C-\><C-N>:lua _G.toggleterm_horizontal()<CR>]], opts)
    vim.keymap.set("t", "<A-t>", [[<C-\><C-N>:ToggleTerm<CR>]], opts)
    vim.keymap.set("t", "<C-/>", [[<C-\><C-N>:lua _G.toggleterm_horizontal()<CR>]], opts)
    vim.keymap.set("t", "<C-_>", [[<C-\><C-N>:lua _G.toggleterm_horizontal()<CR>]], opts)
    vim.keymap.set("t", "<C-\\>", [[<C-\><C-N>:lua _G.toggleterm_floating()<CR>]], opts)
  end
end

-- --------------------------------------------------------------------------
--  Get or create Terminal for this tab + direction
-- --------------------------------------------------------------------------
local function get_terminal(direction, size)
  local ws = get_workspace_info()
  local tab_id = get_tab_id()
  local name = session_name(tab_id, direction)

  _registry[tab_id] = _registry[tab_id] or {}
  _registry[tab_id][ws.host] = _registry[tab_id][ws.host] or {}

  local cached_term = _registry[tab_id][ws.host][direction]
  local cmd
  local display_name
  if ws.is_remote then
    local escaped_remote_cwd = ws.remote_cwd:gsub('"', '\\"')
    local remote_cmd = string.format(
      "tmux has-session -t %s 2>/dev/null || (tmux new-session -d -s %s -c \"%s\" && tmux set -t %s status off); tmux attach -d -t %s",
      name, name, escaped_remote_cwd, name, name
    )
    local remote_cmd_wrapped = "sh -c " .. vim.fn.shellescape(remote_cmd)
    cmd = "ssh " .. ws.host .. " -t " .. vim.fn.shellescape(remote_cmd_wrapped)
    display_name = string.format("%s (%s)", ws.host, direction:sub(1,1):upper() .. direction:sub(2))
  else
    local local_cmd = string.format(
      "tmux has-session -t %s 2>/dev/null || (tmux new-session -d -s %s -c %s && tmux set -t %s status off); tmux attach -d -t %s",
      name, name, vim.fn.shellescape(ws.cwd), name, name
    )
    cmd = "sh -c " .. vim.fn.shellescape(local_cmd)
    display_name = string.format("Local (%s)", direction:sub(1,1):upper() .. direction:sub(2))
  end

  -- If command has changed (e.g. CWD changed), invalidate the cached Terminal
  if cached_term and cached_term.cmd ~= cmd then
    if cached_term:is_open() then
      cached_term:close()
    end
    _registry[tab_id][ws.host][direction] = nil
    cached_term = nil
  end

  if not _registry[tab_id][ws.host][direction] then
    _registry[tab_id][ws.host][direction] =
      require("toggleterm.terminal").Terminal:new({
        cmd = cmd,
        direction = direction,
        size = size,
        close_on_exit = false,
        on_open = make_on_open(direction),
        display_name = display_name,
        shell = "/bin/sh",
      })
  end

  return _registry[tab_id][ws.host][direction]
end

-- --------------------------------------------------------------------------
--  Public API
-- --------------------------------------------------------------------------

function M.toggle_float()
  local tab_id = get_tab_id()
  local ws = get_workspace_info()
  
  _registry[tab_id] = _registry[tab_id] or {}
  _registry[tab_id][ws.host] = _registry[tab_id][ws.host] or {}
  
  local horiz_term = _registry[tab_id][ws.host]["horizontal"]
  if horiz_term and horiz_term:is_open() then
    horiz_term:close()
  end

  get_terminal("float", 15):toggle()
end

function M.toggle_horizontal()
  local tab_id = get_tab_id()
  local ws = get_workspace_info()

  _registry[tab_id] = _registry[tab_id] or {}
  _registry[tab_id][ws.host] = _registry[tab_id][ws.host] or {}

  local float_term = _registry[tab_id][ws.host]["float"]
  if float_term and float_term:is_open() then
    float_term:close()
  end

  get_terminal("horizontal", 20):toggle()
end

function M.get_session_name(direction)
  local tab_id = get_tab_id()
  return session_name(tab_id, direction)
end

function M.list_sessions()
  local tab_id = get_tab_id()
  return {
    float = session_name(tab_id, "float"),
    horizontal = session_name(tab_id, "horizontal"),
  }
end

return M
