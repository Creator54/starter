-- Register worktree keymaps after startup completes
-- (Cannot use LazyVim/LazyVim init — zz_overrides.lua overwrites it)
vim.schedule(function()
  require("util.worktree").setup_keymaps()
end)

return {
  -- 1. Statusline Component for Git Worktrees
  --    Merged into the existing lualine opts function in lualine.lua to
  --    avoid two competing opts functions on the same plugin.
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Preserve the existing onedark theme customisation from lualine.lua
      -- (LazyVim merges all opts functions for the same plugin)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      -- Only insert if we haven't already (idempotent)
      local already_added = false
      for _, comp in ipairs(opts.sections.lualine_x) do
        if type(comp) == "table" and comp._worktree_marker then
          already_added = true
          break
        end
      end

      if not already_added then
        table.insert(opts.sections.lualine_x, 1, {
          _worktree_marker = true, -- dedup marker
          function()
            local wt_mod = require("util.worktree")
            if not wt_mod.in_git_repo() then return "" end
            local worktrees = wt_mod.get_worktrees()
            for _, wt in ipairs(worktrees) do
              if wt.is_current and wt.branch then
                return "󰙅 " .. wt.branch
              end
            end
            return ""
          end,
          color = { fg = "#c678dd", gui = "bold" },
          cond = function()
            return require("util.worktree").in_git_repo()
          end,
        })
      end
    end,
  },
}
