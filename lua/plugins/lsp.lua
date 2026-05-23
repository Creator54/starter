return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          -- Marksman is a .NET app. On NixOS, Mason's pre-compiled .NET binaries
          -- often crash because they cannot find `libicu` in standard FHS paths.
          -- Setting this environment variable bypasses the globalization requirement.
          cmd_env = {
            DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1",
          },
        },
      },
    },
  },
}
