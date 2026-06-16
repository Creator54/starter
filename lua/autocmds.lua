require "nvchad.autocmds"

-- Reset cursor shape to vertical bar on exit
vim.api.nvim_create_autocmd("ExitPre", {
  group = vim.api.nvim_create_augroup("ResetCursorOnExit", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt.guicursor = "a:ver90"
  end,
})

-- Full Background Transparency Override (SRE-friendly absolute transparency)
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

