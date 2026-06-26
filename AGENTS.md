# AGENTS.md

Guide for AI agents working in this Neovim configuration repository.

## What This Is

A personal NvChad v2.5-based Neovim configuration. NvChad is used **as a plugin** (not forked) — `init.lua` imports `nvchad.plugins`, and custom config layers on top via `require "nvchad.options"`, `require "nvchad.mappings"`, `require "nvchad.autocmds"`, and `require "nvchad.configs.lspconfig"`. The `nvchad` branch is the active development branch; `main` tracks the upstream NvChad starter template.

## Repository Layout

```
init.lua                  Bootstrap: lazy.nvim install, plugin loading, theme, options/autocmds/mappings
lua/
  chadrc.lua              NvChad UI config (theme, statusline modules, tabufline, mason packages)
  options.lua             Vim options (extends nvchad.options)
  mappings.lua            Keymaps (extends nvchad.mappings)
  autocmds.lua            Autocmds (extends nvchad.autocmds) — transparency, cursor reset, tab cwd sync
  health/init.lua         Custom :checkhealth nvim-config — verifies external deps and feature state
  configs/                Plugin configuration consumed by specs in plugins/
    lazy.lua              lazy.nvim setup options (icons, disabled builtins, performance)
    lspconfig.lua         LSP server setup (uses vim.lsp.config / vim.lsp.enable API)
    conform.lua           Formatter definitions per filetype
  plugins/                lazy.nvim plugin specs (each file returns a table)
    init.lua              Aggregates plugin specs via { import = "plugins.X" }
    toggleterm.lua, persistence.lua, tmux.lua, remote-sshfs.lua, dap.lua, lint.lua,
    monocle.lua, glow.lua, markdown.lua, kitty-scrollback.lua, scope.lua, ui-select.lua,
    dressing.lua, zen.lua
  util/                   Custom utility modules (the non-obvious part of this config)
    worktree.lua          Git worktree management with floating sidebar UI + session switching
    workspace.lua         Local ↔ SSHFS remote workspace switching with tab-scoped state
    tmux_term.lua         Per-tab tmux-backed toggleterm terminals with persistent registry
.stylua.toml              Lua formatter config (stylua)
lazy-lock.json           Pinned plugin versions — do not hand-edit
```

## Code Style

Formatter: **stylua** (installed via Mason). Config in `.stylua.toml`:
- 120 column width, 2-space indent, Unix line endings
- `quote_style = AutoPreferDouble`, `call_parentheses = None`

Run formatting: `:lua require("conform").format({ lsp_fallback = true })` or `stylua <file>` from shell.

Lua conventions observed across the codebase:
- Module pattern: `local M = {}` ... `return M` for util modules
- `require "module"` (no parens) for top-level requires; `require("module").func()` when calling immediately
- `vim.keymap.set(mode, key, fn, { desc = "...", silent = true })` for keymaps
- `pcall` wrapping around all cross-plugin calls (`require("persistence")`, `require("sshfs...")`, etc.) — defensive against missing plugins
- `vim.fn.system` / `vim.fn.systemlist` for shell commands; check `vim.v.shell_error` for failures
- `vim.defer_fn(fn, ms)` for deferred UI operations (sidebar reopens, refresh)
- `vim.schedule` / `vim.cmd("redrawtabline")` for layout refreshes
- Floating windows: `vim.api.nvim_open_win` with `relative = "editor"`, `style = "minimal"`, `border = "rounded"`

## Kitty Scrollback Mode

The env var `KITTY_SCROLLBACK_NVIM == "true"` is checked in `chadrc.lua`, `options.lua`, and `plugins/persistence.lua` via a local `is_scrollback()` helper. When true, it disables: statusline, tabufline, persistence, auto-save, line numbers, sign column, fold column, winbar. **Any new UI feature must guard against this mode** — check `is_scrollback()` before enabling UI chrome.

## Unified UI System

All user-facing prompts use Neovim's `vim.ui.select` / `vim.ui.input` interface, backed by two plugins:
- **telescope-ui-select** (`plugins/ui-select.lua`) — handles `vim.ui.select` (choices, confirmations, menus)
- **dressing.nvim** (`plugins/dressing.lua`) — handles `vim.ui.input` (text input prompts)

Both provide consistent floating-window UI with telescope theming. **Do not build custom floating-window input/confirm dialogs** — use `vim.ui.input` / `vim.ui.select` instead. They automatically get the right look, keymaps, and theme.

The worktree and workspace hub pickers use `telescope.pickers` directly (not `vim.ui.select`) because they need custom keymaps beyond simple selection (add/delete/merge actions).

## Custom Utility Modules (lua/util/)

These are the most complex and non-obvious parts of the config. Read them before modifying.

### worktree.lua — Git Worktree Manager
- **Sidebar UI** (`toggle_tree`): Opens a 30-width left sidebar (`filetype = "NvimTree"` so NvChad offsets it), lists worktrees with ●/○ current markers and (default) suffix. Keymaps: `<CR>` switch, `a` add, `d` delete, `r` rename, `m` merge, `R` refresh, `q`/`<Esc>` close.
- **Hub UI** (`open_hub`): Telescope picker for quick worktree switching. `<CR>` switch, `a`/`<C-a>` add, `d`/`<C-d>` delete, `m`/`<C-m>` merge. Triggered by `<A-t>`.
- **Prompts**: `vim.ui.input` for worktree naming (via dressing.nvim), `vim.ui.select` for delete/merge confirmation (via telescope-ui-select).
- **Worktree creation**: New worktrees go to `.git/worktrees-checkouts/` (if `.git` is a dir) or `.worktrees/` (fallback, added to `.git/info/exclude`). Creates branch with `git worktree add`.
- **Session switching** (`switch_worktree`): 10-step flow — saves current file to `vim.g.SessionLastFile`, closes sidebars, wipes dir buffers, saves persistence session, wipes all buffers, invalidates git cache, `cd` to new path, loads session, reopens sidebar. **Mutually exclusive with NvimTree** — closes one before opening the other.
- **Delete guard**: `is_default_branch()` prevents deleting main/master. Delete flow switches to default worktree first if deleting the current one.
- **Merge flow**: 5-phase bash script (fetch → check clean → squash merge → commit → cleanup) run in a floating toggleterm. Self-deleting temp script.
- **Git repo cache**: `_cache.in_git_repo` cached per-cwd; call `M.invalidate_cache()` after switching worktrees.
- **Tmux cleanup**: On delete/merge, kills tmux sessions matching the worktree path hash (`sha256:path:sub(1,8)`). Guarded by `vim.fn.executable("tmux")`.

### workspace.lua — Local ↔ Remote Workspace Switching
- **Tab-scoped state**: `vim.t.workspace_is_remote`, `vim.t.workspace_mount_path`, `vim.t.workspace_host_name`, `vim.t.workspace_remote_path`, `vim.t.workspace_local_cwd`.
- **SSHFS integration**: Uses `sshfs.lib.mount_point` `MountPoint.list_active()` to detect mounts. Mounts live in `/tmp/sshfs/`.
- **Switching**: `switch_to_remote(mount_path, host, remote_path)` and `switch_to_local()` — both save/load persistence sessions (with error notification), use `tcd` (tab-scoped cd), clean up buffers, reopen NvimTree.
- **Pins**: `pin_current_folder()` saves remote folders per mount_path to `stdpath("data")/workspace_pins.json`. `prompt_restore()` offers to restore on reconnect (via `vim.ui.select`).
- **Hub UI** (`open_hub`): Telescope picker listing local + active SSH mounts + add-new. `<CR>` switch, `a`/`<C-a>` add new SSH connection.
- **Persistence helpers**: `persistence_save_stop()` and `persistence_load_start()` wrap pcall with `vim.notify` on failure.

### tmux_term.lua — Per-Tab Tmux-Backed Terminals
- **Persistent registry**: `stdpath("data")/tmux_term_registry.json` maps tab IDs to cwd. Survives nvim restarts. Prunes non-existent local dirs on load (remote `/tmp/sshfs/` paths are exempt from pruning).
- **Tab IDs**: `vim.t.tmux_tab_id` — reused by matching cwd, otherwise minted from incrementing counter.
- **Session naming**: `nvim_tab{id}_{direction}_{sha256(project_root):sub(1,8)}` — ties tmux sessions to project root, not just cwd.
- **tmux fallback**: If `tmux` binary is missing, falls back to `cd {dir} && exec ${SHELL:-/bin/sh}`.
- **Remote terminals**: SSH into host, attach/create tmux session there with `status off`. Local cwd is translated to remote path via mount path subtraction.
- **Terminal cache invalidation**: If cached terminal's `cmd` changes (e.g. cwd changed), closes and recreates it.
- **Public API**: `M.toggle_float()`, `M.toggle_horizontal()` — these close the other direction's terminal first (mutual exclusion).

## Session Management (persistence.nvim)

- **Session location**: `stdpath("state")/sessions/{cwd_with_slashes_as_percent}.vim`
- **Auto-restore**: On `VimEnter`, if no file args and cwd isn't `/` or `/tmp`, loads session and opens NvimTree after 300ms.
- **`vim.g.SessionLastFile`**: Stores last active file path before quit/session switch; used to restore focus after session load.
- **Cleanup**: Wipes directory buffers (netrw listings) and nameless empty buffers after `SessionLoadPost` and `PersistenceLoadPost`.
- **Save before switch**: Worktree and workspace switching both call `persistence.save()` then `persistence.stop()` before changing context, then `persistence.load()` + `persistence.start()` after.
- **Quit flow** (`<leader>Q` in mappings.lua): Sets SessionLastFile → NvimTreeClose → %argdelete → wipe dir buffers → persistence.save/stop → wa → qa!

## Transparency System (autocmds.lua)

`clear_bg()` sets `bg = NONE, ctermbg = NONE` on ~100+ highlight groups (Normal, Floats, UI, plugin-specific like Noice/Notify/Snacks/Blink/Telescope/Lazy/Mason). Re-applied on `UIEnter`, `VimEnter`, `ColorScheme`, `BufEnter` with `defer_fn` at 20ms and 100ms. **When adding new floating UI, add its highlight groups to the `groups` table** or backgrounds will be opaque.

## Statusline Custom Modules (chadrc.lua)

- **`git` module**: Custom replacement that shows worktree branch icon (󰙅) instead of default. Reads `vim.b[stbufnr].gitsigns_status_dict`.
- **`cwd` module**: Complex — detects remote workspaces via `vim.t.workspace_is_remote` or `sshfs.lib.mount_point`, translates mount paths to remote paths, shortens long paths (`first/.../last_two`), displays as `host:path`. Falls back to `~` abbreviation for local.

## Key Maps (non-obvious ones)

Leader is `<Space>`. These deviate from NvChad defaults or are custom:

| Key | Action | Notes |
|-----|--------|-------|
| `;` | Command mode | Replaces `:` |
| `jk` | Exit insert mode | |
| `<leader>w` | Toggle git worktree sidebar | **Not save** — overrides typical "write" |
| `<leader>e` | Toggle NvimTree | LazyVim-style; closes worktree sidebar first |
| `<leader>q` | Quit buffer | |
| `<leader>Q` | Bulletproof quit | Saves session + all files, exits cleanly |
| `<A-t>` | Git worktree hub (telescope) | Conflicts with toggleterm default — disabled in toggleterm keys |
| `<A-\`>` (backslash) | Floating terminal | Delegates to `util.tmux_term` |
| `<C-/>`, `<C-_>` | Horizontal terminal | Both mapped to same |
| `<C-d>` | Close buffer | **Not delete char** — overrides default |
| `<S-l>`, `<S-h>` | Next/prev buffer | |
| `<leader>r*` | Remote/workspace prefix | `rc` connect, `rd`/`rl` switch local, `rf` files, `rg` grep, `rw` hub, `rP` pin |
| `<leader>z` | Zen mode | |
| `<leader>a*` | Pi agent prefix | `ap` resume, `an` new, `as` sessions menu, `ac` context (visual/line) |
| `]t`, `[t` | Next/prev tab | |
| `gu`, `gU` | Jump back/forward | Rebinds `<C-o>`/`<C-i>` |

## Toggleterm Global Functions

`_G.toggleterm_floating` and `_G.toggleterm_horizontal` are set in `plugins/toggleterm.lua` config and delegate to `util.tmux_term`. Referenced from `mappings.lua` with existence checks (`if _G.toggleterm_horizontal then`). **Do not call `util.tmux_term` directly from mappings** — use the globals or add new ones in toggleterm config.

## LSP / Formatting / Linting

- **LSP** (`configs/lspconfig.lua`): Uses new `vim.lsp.config()` / `vim.lsp.enable()` API (not the old `lspconfig.xxx.setup()`). Servers: html, cssls, marksman (with `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` env for NixOS).
- **Formatting** (`configs/conform.lua`): per-ft formatters. Format-on-save is **commented out**. Lua→stylua, Python→isort+black, Go→goimports+gofumpt+golines, JS/TS/CSS/HTML/JSON/YAML→prettier, Shell→shfmt.
- **Linting** (`plugins/lint.lua`): `nvim-lint` triggers on `BufWritePost`, `BufReadPost`, `InsertLeave`. Python→flake8, Go→golangci-lint, JS/TS/Vue→eslint_d, Shell→shellcheck.
- **Mason packages** (in `chadrc.lua` `M.mason.pkgs`): stylua, black, isort, flake8, debugpy, gofumpt, goimports, golines, golangci-lint, delve, prettier, eslint_d, js-debug-adapter, shfmt, shellcheck.
- **DAP** (`plugins/dap.lua`): mason-nvim-dap with auto-install for python, delve, js.

## Plugin Import Pattern

`plugins/init.lua` aggregates specs with `{ import = "plugins.X" }` (not `"plugins/X"`). Each plugin file returns a table of specs. Some specs use `config = function() require "configs.X" end` to delegate to `configs/`.

## sshfs.nvim Monkeypatch

`plugins/remote-sshfs.lua` monkeypatches `sshfs.session.connect` to reuse active mounts instead of warning on reconnect. Stashes `vim.g.LastSSHMountDir` / `vim.g.LastSSHHostName` for the `on_mount` hook, which sets tab-scoped workspace state and calls `workspace.save_current_state_once()`.

## External Dependencies & Health Check

External tools are **not** installed by this config — only Mason-managed tools (LSPs, formatters, linters) are auto-installed. The following external binaries are feature-gated and checked at runtime with `vim.fn.executable()`:

| Tool | Feature | Guard Location |
|------|---------|----------------|
| git | Worktree management | `util/worktree.lua` (via `git rev-parse`) |
| tmux | Per-tab terminals, worktree merge/delete cleanup | `util/tmux_term.lua` (shell-level `command -v`), `util/worktree.lua` (`vim.fn.executable`) |
| ssh | Remote terminals, SSHFS | `util/tmux_term.lua` |
| sshfs | Remote workspace mounting | `plugins/remote-sshfs.lua` |
| glow | Markdown preview (`<A-r>`) | `mappings.lua` |
| pi | AI agent integration (`<leader>a*`) | `plugins/monocle.lua` |

Run `:checkhealth nvim-config` to verify all dependencies. The health check (`lua/health/init.lua`) reports which tools are found and which features they enable, plus install hints.

When adding features that call external binaries, **always guard with `vim.fn.executable(name)`** and `vim.notify` on failure with a pointer to `:checkhealth nvim-config`.

## Gotchas

- **`<leader>w` is worktree, not write** — don't "fix" this.
- **`<A-t>` conflict**: toggleterm.lua disables its default `<A-t>` binding (`{ "<A-t>", false }`) because it's remapped to the worktree hub.
- **`<C-d>` is close-buffer**, not delete-char-under-cursor.
- **NvimTree and worktree sidebar are mutually exclusive** — always close one before opening the other.
- **Directory buffers** (netrw listings) pollute sessions — the cleanup pattern (close NvimTree, `%argdelete`, wipe dir buffers) appears in worktree switch, workspace switch, and quit flows. Follow it when adding new context-switching features.
- **`vim.bo[buf].filetype = "NvimTree"`** on the worktree sidebar buffer is intentional — NvChad applies sidebar offset based on this filetype.
- **`buftype = "nofile"` must be set before buffer name** in worktree sidebar creation, or Neovim treats it as a real file.
- **Persistent registries** (`workspace_pins.json`, `tmux_term_registry.json`) live in `stdpath("data")` — use `pcall` around `vim.fn.readfile`/`vim.fn.writefile` and validate JSON decode.
- **Remote path translation**: SSHFS mount paths (`/tmp/sshfs/host_~`) are translated to remote paths (`$HOME/...`) by subtracting mount path prefix. The `~` → `$HOME` conversion appears in multiple places (chadrc cwd module, workspace, tmux_term).
- **Marksman LSP** needs `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` env var (NixOS workaround).
- **Do not build custom float UI for prompts** — use `vim.ui.input`/`vim.ui.select` (backed by dressing.nvim and telescope-ui-select). The worktree hub and workspace hub are the only exceptions — they use `telescope.pickers` directly for custom action keymaps.
