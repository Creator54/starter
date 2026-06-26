return {
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = {
        enabled = true,
        border = "rounded",
        title_pos = "center",
        relative = "editor",
        prefer_width = 50,
        min_width = { 20, 0.2 },
      },
      select = {
        enabled = false, -- telescope-ui-select handles vim.ui.select
      },
    },
  },
}
