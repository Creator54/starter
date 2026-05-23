return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "norg", "rmd", "org" },
    opts = {
      -- Performance optimizations for smooth movement
      render_modes = { "n", "c" }, -- Only render in normal and command modes
      debounce = 100, -- Delay in ms before rendering to prevent lag during fast movement

      heading = {
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      
      -- Disable full-width background for code blocks which is notoriously slow
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
    },
  },
}
