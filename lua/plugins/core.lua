return {
  {
    "creator54/onedark.nvim",
    config = function()
      require("onedark").setup({
        style = 'darker'
      })
      require("onedark").load()
    end,
  },
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
      colorscheme = "onedark",
    }
  }
}
