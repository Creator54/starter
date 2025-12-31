return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Attempt to load the onedark theme for lualine
      local ok, custom_theme = pcall(require, "lualine.themes.onedark")
      if not ok then
        -- Fallback to the current theme if onedark isn't found
        custom_theme = opts.options.theme
        if type(custom_theme) == "string" then
          ok, custom_theme = pcall(require, "lualine.themes." .. custom_theme)
        end
      end

      if ok and type(custom_theme) == "table" then
        -- Safely set background to NONE for the 'c' section across all modes
        local modes = { "normal", "insert", "visual", "replace", "command", "inactive" }
        for _, mode in ipairs(modes) do
          if custom_theme[mode] then
            custom_theme[mode].c = custom_theme[mode].c or {}
            custom_theme[mode].c.bg = "NONE"
          end
        end
        opts.options.theme = custom_theme
      end
    end,
  },
}
