return {
  -- 1. Ensure tools are installed via Mason
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Lua (for Neovim config)
        "stylua",
        -- Python
        "black",
        "isort",
        "flake8",
        "debugpy", -- Python DAP
        -- Go
        "gofumpt",
        "goimports",
        "golines",
        "golangci-lint",
        "delve", -- Go DAP
        -- JS/TS/Web
        "prettier",
        "eslint_d",
        "js-debug-adapter", -- JS/TS DAP
        -- Shell
        "shfmt",
        "shellcheck",
      },
    },
  },

  -- 2. Configure Formatters with conform.nvim
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Python formatting (isort sorts imports, black formats code)
        python = { "isort", "black" },
        
        -- Go formatting
        go = { "goimports", "gofumpt", "golines" },
        
        -- Web / JS / TS formatting
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        graphql = { "prettier" },
        
        -- Shell formatting
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        fish = { "fish_indent" },
      },
    },
  },

  -- 3. Configure Linters with nvim-lint
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Python linting
        python = { "flake8" },
        
        -- Go linting
        go = { "golangci-lint" },
        
        -- Web / JS / TS linting
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
        
        -- Shell linting
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
}