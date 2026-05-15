return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      highlight = {
        disable = { "neo-tree" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      exclude = { "neo-tree" },
    },
  },
}
