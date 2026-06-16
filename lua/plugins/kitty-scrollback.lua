return {
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
    event = { "User KittyScrollbackLaunch" },
    opts = {},
    config = function(_, opts)
      require("kitty-scrollback").setup(opts)

      -- Extra cleanup when the plugin is launched
      vim.api.nvim_create_autocmd("User", {
        pattern = "KittyScrollbackLaunch",
        callback = function()
          -- Ensure UI is stripped if NvChad init was too early
          vim.opt.laststatus = 0
          vim.opt.showtabline = 0
          vim.opt.number = false
          vim.opt.relativenumber = false
          vim.opt.signcolumn = "no"
          vim.opt.foldcolumn = "0"
          vim.opt.winbar = ""

          -- Close any remaining sidebars
          pcall(vim.cmd, "NvimTreeClose")

          -- Set the global flag just in case
          vim.g.kitty_scrollback_mode = true
        end,
      })
    end,
  },
}
