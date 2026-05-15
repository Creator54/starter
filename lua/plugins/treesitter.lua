return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      opts.highlight.disable = function(lang, buf)
        return lang == "neo-tree" or vim.bo[buf].filetype == "neo-tree"
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = false,
  },
}
