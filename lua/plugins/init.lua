return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  { import = "plugins.toggleterm" },
  { import = "plugins.persistence" },
  { import = "plugins.kitty-scrollback" },
  { import = "plugins.monocle" },
  { import = "plugins.markdown" },
  { import = "plugins.tmux" },
  { import = "plugins.zen" },
  { import = "plugins.lint" },
  { import = "plugins.glow" },
  { import = "plugins.dap" },
  { import = "plugins.remote-sshfs" },
  { import = "plugins.scope" },
  { import = "plugins.ui-select" },
}


