-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local function clear_bg()
  local groups = {
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle", "SignColumn",
    "EndOfBuffer", "MsgArea", "TabLine", "TabLineFill", "TabLineSel", "BufferLineFill",
    "BufferLineBackground", "BufferLineSeparator", "WinSeparator", "VertSplit",
    "NormalSB", "StatusLine", "StatusLineNC", "LineNr", "CursorLine", "CursorLineNr",
    "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb", "Folded", "FoldColumn", "WinBar",
    "WinBarNC", "NoiceCmdlinePopup", "NoiceCmdlinePopupBorder", "NoiceCmdlinePopupTitle",
    "NoiceCmdlineIcon", "NoiceCompletionItemKindDefault", "CmpPmenu", "CmpPmenuBorder",
    "CmpDoc", "CmpDocBorder", "BlinkCmpMenu", "BlinkCmpMenuBorder", "BlinkCmpDoc",
    "BlinkCmpDocBorder", "WhichKey", "WhichKeyFloat", "WhichKeyBorder", "WhichKeyNormal",
    "LazyNormal", "LazyBorder", "MasonNormal", "MasonBorder", "TelescopeNormal",
    "TelescopeBorder", "TelescopePromptNormal", "TelescopePromptBorder",
    "TelescopeResultsNormal", "TelescopeResultsBorder", "TelescopePreviewNormal",
    "TelescopePreviewBorder", "NotifyNormal", "NotifyBorder", "NotifyBackground",
    "NotifyINFONormal", "NotifyWARNNormal", "NotifyERRORNormal", "NotifyDEBUGNormal",
    "NotifyTRACENormal", "NotifyINFOBody", "NotifyWARNBody", "NotifyERRORBody",
    "NotifyDEBUGBody", "NotifyTRACEBody", "NotifyINFOBorder", "NotifyWARNBorder",
    "NotifyERRORBorder", "NotifyDEBUGBorder", "NotifyTRACEBorder", "NotifyINFOTitle",
    "NotifyWARNTitle", "NotifyERRORTitle", "NotifyDEBUGTitle", "NotifyTRACETitle",
    "NotifyINFOIcon", "NotifyWARNIcon", "NotifyERRORIcon", "NotifyDEBUGIcon",
    "NotifyTRACEIcon", "NoiceMini", "NoiceMiniBorder", "NoiceCmdline", "NoiceCmdlineBorder",
    "NoiceNotificationNormal", "NoiceNotificationBorder", "NoiceNotificationTitle",
    "NoicePopupNormal", "NoicePopupBorder", "NoicePopupTitle", "NoiceLspProgressNormal",
    "NoiceLspProgressBorder", "NoiceLspProgressTitle", "NoiceConfirmNormal",
    "NoiceConfirmBorder", "NoiceConfirmTitle", "NoiceHoverNormal", "NoiceHoverBorder",
    "NoiceHoverTitle", "NoiceMessageNormal", "NoiceMessageBorder", "NoiceMessageTitle",
    "SnacksNormal", "SnacksNormalNC", "SnacksBorder", "SnacksTitle", "SnacksNotifierNormal",
    "SnacksNotifierBorder", "SnacksNotifierTitle", "SnacksNotifierIcon", "SnacksNotifierInfo",
    "SnacksNotifierWarn", "SnacksNotifierError", "SnacksNotifierDebug", "SnacksNotifierTrace",
    "SnacksNotifierInfoNormal", "SnacksNotifierWarnNormal", "SnacksNotifierErrorNormal",
    "SnacksNotifierDebugNormal", "SnacksNotifierTraceNormal", "SnacksNotifierHistoryNormal",
    "SnacksNotifierHistoryBorder", "SnacksNotifierHistoryTitle", "SnacksBackdrop",
    "DiagnosticFloatingError", "DiagnosticFloatingWarn", "DiagnosticFloatingInfo",
    "DiagnosticFloatingHint", "DiagnosticNormal", "FloatShadow", "FloatShadowThrough",
    "lualine_c_normal", "lualine_c_insert", "lualine_c_visual", "lualine_c_replace",
    "lualine_c_command", "lualine_c_inactive",
  }
  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
  end
end

clear_bg()

local transparency_group = vim.api.nvim_create_augroup("TransparentStartup", { clear = true })
vim.api.nvim_create_autocmd({ "UIEnter", "VimEnter", "ColorScheme", "BufEnter" }, {
  group = transparency_group,
  callback = function()
    clear_bg()
    vim.defer_fn(clear_bg, 20)
    vim.defer_fn(clear_bg, 100)
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = transparency_group,
  pattern = "LazyVimStarted",
  callback = clear_bg,
})

-- THE FIX: Silence Treesitter parser errors for Neo-tree
-- Registering markdown as a fallback for neo-tree stops the "No parser" warning
vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  callback = function()
    pcall(vim.treesitter.language.register, "markdown", "neo-tree")
    pcall(vim.treesitter.stop)
  end,
})
