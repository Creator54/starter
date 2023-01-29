return {
  { "navarasu/onedark.nvim" },
  {
    "jackMort/ChatGPT.nvim",
    config = function()
    require("chatgpt").setup({
    -- optional configuration
    })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "habamax",
    }
  }
}
